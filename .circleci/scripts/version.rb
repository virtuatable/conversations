#!/usr/bin/env ruby
require 'gitlab'
require 'semantic'
require 'logger'
require 'json'

def docker_url
  "https://registry.hub.docker.com/v2/repositories/virtuatable/conversations/tags?ordering=last_updated"
end

def docker_params
  {
    page: 1,
    page_size: 1,
    ordering: 'last_updated'
  }
end

def client
  Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
end

def current_version
  body = JSON.parse(Faraday.get(docker_url, docker_params).body)
  results = body['results']
  raw_version = results.empty? ? '0.0.0': results.first['name']
  Semantic::Version.new(raw_version)
end

def next_version
  current_version.increment!(increment)
end

def increment
  ['major', 'minor'].each do |label|
    return label if labels.include? label
  end
  'patch'
end

def pull_request
  repository = 'virtuatable/conversations'
  requests = client.pull_requests(repository, {state: 'all'})
  requests.find { |r| r[:merge_commit_sha] == ENV['CI_COMMIT_SHA'] }
end

def labels
  return [] if pull_request.nil?
  return pull_request[:labels].map { |l| l[:name] }
end

if ARGV.first == 'next'
  puts next_version.to_s
else
  puts current_version.to_s
end