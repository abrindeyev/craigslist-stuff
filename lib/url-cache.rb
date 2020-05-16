require 'open-uri'
require 'rest-client'
require 'json'
require './lib/debugger'
require './lib/mongodb'

class URLCacher < Debugger

  @@db = nil
  @@api_key = File.open("#{ENV['HOME']}/.google_maps_api_key.txt", &:readline)

  def initialize(db)
    unless @@db
      @@db = MDB.new.database
    end
    self
  end

  def get_cached_json(url)
    c = @@db[:url_cache]
    cached = nil
    c.find({ _id: url}).each do |d|
      cached = d
    end
    if not cached.nil? and cached.include?(:body)
      c.update_one({ _id: url},{'$inc':{hits:1}})
      debug("Returning cached document for #{url}")
      return cached[:body]
    end

    debug("Checking rate-limiter")
    r = nil
    begin
      r = @@db[:rate_limiter].update_one({ _id: Time.now.to_i}, {'$inc':{c:1}}, { :upsert => true })
      sleep 0.05 if r and r.upserted_id.nil?
    rescue Mongo::Error::OperationFailure => e
      raise e if e.message !~ /E11000/
    end while r.upserted_id.nil?

    full_url = "#{url}&key=#{@@api_key}"
    debug("Requesting #{full_url}")
    begin
      req = RestClient::Request.new(
        :method => :get,
        :url => full_url,
        :timeout => 5,
        :open_timeout => 3,
        :headers => {
          "User-Agent" => "curl/7.51.0"
        }
      )
      resp = req.execute
    rescue RestClient::ExceptionWithResponse => e
      debug("Failed to query Google Maps API, error: #{e.response}")
      debug("Request headers: #{req.processed_headers.inspect}")
      raise e
    end
    body = JSON.parse(resp.body)
    cached = {
      :_id => url,
      :body => body,
      :code => resp.code,
      :headers => resp.headers,
      :hits => 1,
    }
    c.insert_one(cached, { :upsert => true })
    sleep 0.25
    return body
  end

  def purge_cache(url)
    c = @@db[:url_cache]
    c.find({ _id: url}).delete_one
  end

end
