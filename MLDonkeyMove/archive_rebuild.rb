#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-12-03.
#  Copyright (c) 2006. All rights reserved.
require 'rubygems'
require 'fileutils'

VIDEO_SRC = ["/vault/tv1", "/vault/tv2", "/vault/tv3", "/vault/med01/video/completed"]

class ArchiveVideos
  class << self
    def span_sources(locations)
      year_dirs=locations.collect {|x| Dir.glob(File.join(x,'**')).collect {|y| y}}.flatten
      programmes=year_dirs.collect {|x| Dir.glob(File.join(x,'**')).collect {|y| y}}.flatten
      programmes.each {|programme| span_seasons(programme)}
    end

    def span_seasons(programme)
      seasons=Dir.glob(File.join(programme,'Season*')).collect {|y| y}
      new_seasons=[]
      seasons.each do |x|
        case x
        when /\/(\d\d\d\d)\/.*\/Season(\d\d)/
          year=$1.to_i
          season=$2.to_i
          year+=season-1 unless season==0
          if year < 2011
            new_seasons << x.gsub(/\/(\d\d\d\d)\//,"/#{year}/")
          else
            new_seasons << x
          end
        end
      end
      new_seasons.size.times do |x|
        next if seasons[x]==new_seasons[x]
        puts("Moving from #{seasons[x]} to #{new_seasons[x]}")
        FileUtils.mkdir_p(new_seasons[x])
        Dir.glob(File.join(seasons[x],'*')).each do |file|
          puts("Moving #{file}")
          FileUtils.mv(file,new_seasons[x])
        end
      end
    end
  end
end

ArchiveVideos::span_sources(VIDEO_SRC)