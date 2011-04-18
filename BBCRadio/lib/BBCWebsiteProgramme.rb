#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'

BBCROOT="http://www.bbc.co.uk"

class BBCWebsiteProgramme
  def initialize(url)
    @url=url
    @webpage=nil
  end
  def fetch
    @webpage={}
    doc=Hpricot(open(BBCROOT+@url))
    rpm=(doc/"//embed").first.attributes['src']
    @webpage[:rtsp]=(open(BBCROOT+rpm) {|f| f.read}).gsub!(/\?BBC-UID.*/,"")
    show=(doc/"div#showtitle")
    @webpage[:name]=(show/"big").innerText
    @webpage[:duration]=(show/"span.txinfo").innerText
    @webpage[:description]=(show/"table").innerText
    @webpage
  end
  def webpage
    @webpage || fetch
  end
  def description
    webpage[:description]
  end
  def name
    webpage[:name]
  end
  def duration
    webpage[:description]
  end
  def channel
    webpage[:channel]
  end
  def start
    webpage[:start]
  end
  def title
    webpage[:title]
  end
  def rtsp
    webpage[:rtsp]
  end
end

