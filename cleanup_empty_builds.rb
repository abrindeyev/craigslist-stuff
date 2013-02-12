#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rest-client'
require 'uri'
require 'json'

STDOUT.sync = true

job = 'craigslist-app-cd'

job_metadata_uri = "#{ENV['JENKINS_URL']}/job/#{job}/api/json"
resp = RestClient.get(job_metadata_uri)
job_metadata = JSON.parse(resp.body)

exit unless job_metadata.include?('builds')

to_delete = []
job_metadata['builds'].each do |build|
  # get status of build
  build_metadata_uri = build['url'] + 'api/json'
  build_metadata = JSON.parse(RestClient.get(build_metadata_uri).body)
  next unless build_metadata['result'] == 'SUCCESS' # skipping failed builds
  build_console = RestClient.get("#{build['url']}consoleText").body
  to_delete << build['number'] unless build_console.scan('************ PROCESSED LINKS ************').size > 0
end

system("java -jar jenkins-cli.jar -s #{ENV['JENKINS_URL']} delete-builds #{job} " + to_delete.join(',')) if to_delete.size > 0
