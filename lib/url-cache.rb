require 'open-uri'
require 'rest-client'
require 'json'
require './lib/debugger'

class URLCacher < Debugger

  @@db = nil

  def initialize(db)
    unless @@db
      @@db = db
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
    debug("Requesting #{url}")
    resp = RestClient.get(url)
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
