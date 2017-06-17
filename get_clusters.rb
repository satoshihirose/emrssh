#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'aws-sdk'
require 'pp'
require 'inifile'
require 'optparse'
require 'yaml'

CONFIG = File.join(Dir.home, '.aws', 'config').freeze
CACHE = File.join(Dir.home, '.emrssh').freeze
CACHE_TTL = 3600
CLUSTER = Struct.new(:cluster_id, :cluster_name, :public_dns_name, :status, :release_label, :tags, :create_date)

profile = 'default'
opts = {}
OptionParser.new do |opt|
  opt.banner = "Usage: #{opt.program_name} [options]"
  opt.on('-h', '--help', 'Show usage') { puts opt.help ; exit }
  opt.on('-f', '--flush', 'Flush cache') { opts[:ignore] = true }
  opt.on('-p PROFILE', '--profile PROFILE', 'Specify profile') { |v|
    profile = "profile #{v}"
    Aws.config[:credentials] = Aws::SharedCredentials.new(profile_name: profile)
  }
  opt.parse!(ARGV)
end

ini = IniFile.load(CONFIG)
region = ENV['REGION'] || ini[profile]['region']
Aws.config[:region] = region

clusters = []
# load cache if fresh
if File.exist?(CACHE) && opts[:ignore].nil?
  mtime = File::Stat.new(CACHE).mtime
  if Time.now - mtime < CACHE_TTL
    cache = YAML.load_file(CACHE)
    clusters = cache[profile][region] rescue nil
  end
end

if clusters.empty?
  emr = Aws::EMR::Client.new
  list = emr.list_clusters({
    cluster_states: ["STARTING","BOOTSTRAPPING","RUNNING","WAITING"]
  })
  clusters = list.clusters.map! do |cluster|
    detail = emr.describe_cluster({
      cluster_id:  cluster.id
    })
    CLUSTER.new(cluster.id,
                 cluster.name,
                 detail.cluster.master_public_dns_name,
                 detail.cluster.status.state,
                 detail.cluster.release_label,
                 detail.cluster.tags,
                 detail.cluster.status.timeline.creation_date_time,
               )
  end
  File.open(CACHE, 'w') { |f|
    cache = { profile => { region => clusters } }
    YAML.dump(cache, f)
  }
end

clusters.each do |cluster|
  user = 'hadoop'
  name = cluster.cluster_name
  dnsname = cluster.public_dns_name
  status = cluster.status
  release_label = cluster.release_label
  create_date = cluster.create_date
  cluster.tags.each do |tag|
    name = tag.value if tag.key =~ /^name/i
    user = tag.value if tag.key =~ /^user/i
  end
  puts "#{cluster.cluster_id}\t#{status}\t#{release_label}\t#{user}@#{dnsname}\t#{create_date}\t\"#{name}\"\t"
end
