#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-11-08.
#  Copyright (c) 2006. All rights reserved.
require "zlib"
require "ftools"


class TVAnyTime
  attr_reader :site, :localdir
  def initialize(download_url="http://backstage.bbc.co.uk/feeds/tvradio/",localdir="~/.borg/TVAnyTime")
    File.makedirs(localdir) if not File.exists?(localdir)
    @localdir=localdir
    @site=download_url
  end
  def get_file(date)
    
  end
end

tv=TVAnyTime.new()
test=File.join(tv.site,"20061108.tar.gz")
print test+"\n"
# TCP connection with a time out
require 'socket'
require 'timeout'
begin
  timeout(1) do #the server has one second to answer
    t = TCPSocket.new('backstage.bbc.co.uk', 'www')
  end
rescue
    puts "error: #{$!}"
else
    t.print "GET / HTTP/1.0\n\n"
    answer = t.gets(nil)
    # and terminate the connection when we're done
    t.close
end
