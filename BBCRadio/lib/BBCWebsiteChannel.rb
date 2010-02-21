#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'

class BBCWebsiteChannel
  attr_reader :name, :urls, :streams

  def initialize(name,urls=[],streams=[])
    @name=name.to_sym
    urls=[urls] unless urls.kind_of?(Array)
    @urls=urls
    @streams=streams || build_streams(urls) unless urls.nil?
    @active_stream=0
    @active_url=0
  end
  
  def url(option=:current)
    @urls[@active_url]
  end
  
  def stream(option=:current)
    case option
    when :first
      @active_stream=0
    when :last
      @active_stream=@streams.size
    when :next
      @active_stream+=1
      @active_stream=0 if @active_stream > @streams.size
    when :prev
      @active_stream-=1
      @active_stream=@streams.size if @active_stream<0
    end
    @streams[@active_stream]
  end

  def to_yaml(opts={})
    {:streams=>@streams,:urls=>@urls}.to_yaml(opts)
  end
    
  def add_urls(urls,build=false)
    urls=[urls] unless urls.kind_of?(Array)
    @urls+=urls
    @streams+=(urls.collect {|url| build_streams(url)}).flatten if build
    @streams
  end
  
  def build_streams(url)
    print("#{name} building from #{url}\n")
    uri=URI.parse(url)
    extension=File.extname(uri.path)
    case extension
    when ".asx"
      (Hpricot(open(url))/"ref").collect do |x|
        test=x.attributes['href']
        build_streams(test)
      end
    when ".ram"
      open(url) {|f| f.readlines}
    else
      url.gsub(/\?BBC-UID=.*/,'')
    end
  end
  
  def play(player)
    player.play(@streams[@active_stream])
  end
end