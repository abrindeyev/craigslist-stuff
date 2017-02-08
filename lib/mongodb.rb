require 'mongo'
require 'yaml'
require 'openssl'
require './lib/debugger'

class MDB < Debugger

  @@mc = nil

  def initialize()
    if @@mc
      debug("Returning cached MongoDB connection")
    else
      debug("Setting up new MongoDB connection")
      if ENV['MONGO_DEBUG']
        Mongo::Logger.logger.level = ::Logger::DEBUG
      else
        Mongo::Logger.logger.level = ::Logger::FATAL
      end
      db_settings_fn = ENV['CG_DB'] ? ENV['CG_DB'] : "#{ENV['HOME']}/.cg_db.yml"
      if File.exists?(db_settings_fn)
        debug("Using the following database settings file: #{ db_settings_fn }")
      else
        raise "Database settings file #{ db_settings_fn } not found"
      end
      settings = YAML.load_file(db_settings_fn)
      db_settings = settings[:settings]
      replica_set_hosts = settings[:hosts]

      if db_settings.has_key?(:auth) and db_settings[:auth] == true
        debug("Setting up authentication settings for the connection")
        db_settings.delete(:auth) # to make Mongo Ruby driver happy
        raise "Please specify MongoDB authentication mechanism via :auth_mech" unless db_settings.has_key?(:auth_mech)
        if db_settings[:auth_mech] == :mongodb_x509
          raise "Please specify client certificate in :ssl_cert" unless db_settings.has_key?(:ssl_cert) and File.exists?(db_settings[:ssl_cert])
          db_settings[:user] = OpenSSL::X509::Certificate.new(File.read(db_settings[:ssl_cert])).subject.to_s(OpenSSL::X509::Name::RFC2253)
          db_settings.delete(:password) if db_settings.has_key?(:password)
        elsif db_settings[:auth_mech] == :scram
          raise "Please specify :user & :password for :scram authentication mechanism" unless db_settings.has_key?(:user) and db_settings.has_key?(:password)
        else
          raise "Please add support for the #{ db_settings[:auth_mech] } authentication mechanism"
        end
      else
        db_settings.delete(:auth) if db_settings.has_key?(:auth)
        db_settings.delete(:auth_mech) if db_settings.has_key?(:auth_mech)
        db_settings.delete(:user) if db_settings.has_key?(:user)
        db_settings.delete(:password) if db_settings.has_key?(:password)
      end
      debug("Connecting to the #{ db_settings[:replica_set] } replica set: #{db_settings.inspect}")
      @@mc = Mongo::Client.new(replica_set_hosts, db_settings)
    end
    self
  end

  def client()
    @@mc if @@mc
  end

  def database()
    @@mc.database if @@mc
  end
end
