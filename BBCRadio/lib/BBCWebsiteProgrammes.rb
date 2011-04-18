#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'



class BBCWebsiteProgramme
  def initialize(name,url=nil)
    @name=name
    @url=url
    @description=nil
    @original_name=nil
    @rtsp=nil
  end
  def list
    
  end
end

