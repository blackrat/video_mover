#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'
require 'BBCWebsiteChannel'

class BBCWebsiteChannels
  attr_reader :name, :urls, :channels

  def initialize(name,urls=[])
    @name=name.to_sym
    urls=[urls] unless urls.kind_of?(Array)
    @urls=urls
    @channels={}
    fetch(@urls) unless urls.nil? || urls.empty?
  end

  def add(urls,channels,build=false)
    add_urls(urls,build)
    add_channels(channels)
  end

  def to_yaml(opts={})
    {:class=>'BBCWebsiteChannels',:urls=>@urls,:channels=>@channels}.to_yaml(opts)
  end

  def add_urls(urls=[],build=false)
    urls=[urls] unless urls.kind_of?(Array)
    @urls+=urls
    fetch(urls) if build
  end

  def add_channels(channels={})
    return if channels.nil? || channels.empty?
    channels.each do |k,v|
      @channels[k]||=BBCWebsiteChannel.new(k,v[:urls],v[:streams])
    end
  end

  def fetch(urls)
    urls=[urls] unless urls.kind_of?(Array)
    channels={}
    urls.each do |url|
      doc=Hpricot(open(url))
      confluence=doc/"td.confluenceTd/.."
      if confluence.empty?
        (doc/"#theContent//ul/li/a").each do |x|
          name=(x).innerText.gsub(/[\s-]/,'').gsub(/WMA/,'').downcase
          if name=~/^[bbc|radio]/
            build=@channels[name.to_sym].nil?
            @channels[name.to_sym]||=BBCWebsiteChannel.new(name)
            @channels[name.to_sym].add_urls(x.attributes['href'],build)
          end
        end
      else
        confluence.each do |y|
          begin
            (y/"td.confluenceTd").each_slice(2) do |x|
              name=x[0].innerText.gsub(/[\s-]/,'').gsub(/WMA/,'').downcase
              value=(x[1]/"//a").first.attributes['href']
              if name=~/^[bbc|radio]/
                build=@channels[name.to_sym].nil?
                @channels[name.to_sym]||=BBCWebsiteChannel.new(name)
                @channels[name.to_sym].add_urls(value,build)
              end
            end
          rescue
            next
          end
        end
      end
    end
    channels
  end
end
