#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'
require 'nokogiri'
require 'thread'
require './lib/address'
require './lib/school'
require './lib/url-cache'
require './lib/mt-mongo'

class Parser < Nokogiri::XML::SAX::Document
  @object = nil
  @otype = nil
  @mc = nil
  @@OSM_USERS = {}
    @@type_map = {
      "id" => "Integer",
      "uid" => "Integer",
      "visible" => "Boolean",
      "version" => "Integer",
      "changeset" => "Integer",
      "timestamp" => "Time",
      "user" => "String",
      "lat" => "Decimal",
      "lon" => "Decimal"
    }

  def initialize(mc)
    @mc = mc
  end

  def start_element(name, attrs = [])
    return unless ['node','way','relation','tag','member','nd'].include?(name)
    case name
    when 'node'
      @otype = name
      @object = self.parse_attributes(attrs)
    when 'way'
      @otype = name
      @object = self.parse_attributes(attrs)
    when 'relation'
      @otype = name
      @object = self.parse_attributes(attrs)
    when 'tag'
      @object['tags'] = {} unless @object.include?('tags')
      t = Hash[*attrs.flatten]
      @object['tags'][ t['k'].gsub(/\./, '_') ] = t['v']
    when 'member'
      @object['members'] = [] unless @object.include?('members')
      t = Hash[*attrs.flatten]
      t['ref'] = t['ref'].to_i
      @object['members'].push t
    when 'nd'
      @object['nd'] = [] unless @object.include?('nd')
      t = Hash[*attrs.flatten]
      @object['nd'].push t['ref'].to_i
    else
      raise "WTF is #{name} in start_element?"
    end
  end

  def parse_attributes(as)
    res = {}
    as.each do |sa|
      k = sa[0]
      v = sa[1]
      case @@type_map[k]
      when "Integer"
        res[k] = v.to_i
      when "Boolean"
        if v == "true"
          res[k] = true
        elsif v == "false"
          res[k] = false
        else
          res[k] = nil
        end
      when "String"
        res[k] = v.to_s
      when "Decimal"
        res[k] = BSON::Decimal128.from_string(v.to_s)
      when "Time"
        res[k] = DateTime.parse(v.to_s)
      else
        raise "Invalid type for attribute #{k}: #{@@type_map[k]}"
      end
    end
    res['_id'] = res.delete('id')
    @@OSM_USERS[ res['uid'] ] = res.delete('user')
    res
  end

  def process_users()
    @@OSM_USERS.each do |id,name|
      collect_write('osm_users', {
        :update_one => {
          :filter => { _id: id.to_i},
          :update => { "$set": {'_id' => id.to_i, 'name' => name} },
          :upsert => true}
      })
    end
  end

  def characters(string)
    return
  end

  def end_element(name)
    return unless ['node','way','relation'].include?(name)
    delete_requested = false
    no_op = false
    case name
    when 'node'
      no_op = false
      c = 'osm_nodes'
      @object['l'] = { 'type' => 'Point', coordinates: [ @object.delete('lon'), @object.delete('lat') ] }
    when 'way'
      c = 'osm_ways'
      if @object.include?('nd')
        if @object['nd'].size == 1 or (@object['nd'].size == 2 and @object['nd'][0] == @object['nd'][1])
          delete_requested = true
        else
          nodes = {}
          @mc['osm_nodes'].find({_id: {'$in': @object['nd']}}).each { |n| nodes[ n['_id'] ] = n['l']['coordinates'] }
          @object['l'] = {
            'type' => 'LineString',
            'coordinates' => @object['nd'].map {|ref| nodes[ref] }
          }
        end
        #if @object.include?('tags')
        #  t = @object.delete('tags')
        #  # Flattenning tags from an object into an array
        #  @object['tags'] = t.keys.map {|k| "#{k}=#{ t[k] }" }
        #end
        #@object.delete('nd')

        # Inserting back-references to nodes
        collect_write('osm_nodes', {
          :update_many => {
            :filter => { _id: {'$in': @object['nd']}},
            :update => { '$addToSet' => {'w' => @object['_id']}}
          }})
      end
    when 'relation'
      no_op = false
      c = 'osm_relations'
    else
      raise "WTF is #{name} in end_element?"
    end

    selection = { _id: @object["_id"] }
    updates = { "$set": @object }
    unless no_op
      if delete_requested
        collect_write(c, {
          :delete_one => {
            :filter => selection,
          }})
      else
        collect_write(c, {
          :update_one => {
            :filter => selection,
            :update => updates, 
            :upsert => true
          }})
      end
    end
    @object = nil
  end
end

def log(msg)
  puts "#{ Time.now.strftime('%Y.%m.%d %H:%M:%S.%6N') } #{msg}"
end

def collect_write(coll, obj)
  $queues[coll] << obj
end

puts '-------------------------------------------------------'

mc = MDB.new.client

mc['osm_nodes'].drop()
mc['osm_ways'].drop()
mc['osm_relations'].drop()
mc['osm_users'].drop()

$queues = {
  'osm_nodes'     => Queue.new,
  'osm_ways'      => Queue.new,
  'osm_relations' => Queue.new,
  'osm_users'     => Queue.new
}

producer = Thread.new do
  p = Parser.new(mc)
  log("Starting parsing...")
  Nokogiri::XML::SAX::Parser.new(p).parse(File.open(ARGV[0]))
  log("Processing users...")
  p.process_users
  $queues.each do |coll,queue|
    log("Closing queue for the #{coll} collection")
    queue.close
  end
  log("All queues were closed")
end

consumers = []
$queues.keys.each do |collection|
  2.times do
    consumers << Thread.new(collection) do |coll|
      puts "Starting consumer thread for the #{coll} collection"
      mc = MDB.new.client
      q = $queues[coll]
      writes = []
      docs_count = 10240

      while not q.closed?
        w = q.pop # consumer thread will block here
        writes << w unless w.nil?
        log("The #{coll} queue was closed") if w.nil?
        if writes.size > docs_count or w.nil?
          begin
            log("Sending the batch of #{writes.size} documents to the #{coll} collection, queue size: #{q.size}")
            r = mc[coll].bulk_write(writes, :ordered => false)
          rescue Mongo::Error::OperationsFailure => e
            raise e if e.message !~ /E11000/
          end
          writes = []
        end
      end    
    end
  end
end

producer.join
consumers.each do |th|
  th.join
end

#puts "Creating indices:"
#mc['osm_nodes'].indexes.create_one({l: '2dsphere'})
#mc['osm_ways'].indexes.create_one({l: '2dsphere'})

# Get rid of no-use nodes (once you use them for osm_ways)
# mc['osm_nodes'].delete_many({tags:{'$exists': false}})
log("Done!")
