#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-12-03.
#  Copyright (c) 2006. All rights reserved.
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'yaml'

VAULT_STORE = File.expand_path("~/.borg/first_aired")
VIDEO_SRC = ["/vault/tv1",'/vault/tv2','/vault/tv3']
API_KEY="251551148FAFB4DA"

class YearOutOfBounds < RuntimeError; end

 def url_encode(s)
   s.to_s.gsub(/[^a-zA-Z0-9_\-.]/n){ sprintf("%%%02X", $&.unpack("C")[0]) }
 end

class ArchiveVideos
  class << self

    def span_sources(locations)
      year_dirs=locations.collect {|x| Dir.glob(File.join(x,'**')).collect {|y| y}}.flatten
      programmes=year_dirs.collect {|x| Dir.glob(File.join(x,'**')).collect {|y| y}}.flatten
      programmes.each {|programme| span_seasons(programme)}
    end

    def get_from_thetvdb(name)
      begin
        doc = Nokogiri::XML(open("http://thetvdb.com/api/GetSeries.php?seriesname=#{url_encode(name)}"))
        year=(doc.css("Data/Series/FirstAired").text).split('-')[0].to_i
        year
      rescue Exception=>e
        puts(e)
        nil
      end
    end

    def save_to_file
      File.open(VAULT_STORE,'w+') {|fd| YAML.dump(@programme_hash,fd)}
    end

    def get_from_file(name)
      begin
        details=YAML.load_file(VAULT_STORE)
        details[name]
      rescue Exception=>e
        puts(e)
        nil
      end
    end

    def programme_find_year(programme_name)
      @programme_hash||=Hash.new do |first_aired,name|
        spool=false
        val=get_from_file(name)
        if val.nil?
          val=get_from_thetvdb(name)
          spool=true
        end
        first_aired[name]=val
        save_to_file if spool
        val
      end
      @programme_hash[programme_name]
    end

    def season_fixup(directory)
      programmes=Dir.glob(File.join(directory,'**')).collect {|y| y.gsub("#{directory}/",'')}
      programmes.each do |x|
        if directory.include?(x)
          Dir.glob(File.join(directory,x,'**')).each do |y|
            FileUtils.mv(y,directory)
          end
        end
      end
      puts(programmes)
    end

    def span_seasons(programme)
      programme_name=programme.split('/')[-1].split('_').join(' ')
      programme_year=programme_find_year(programme_name)
      seasons=Dir.glob(File.join(programme,'Season*')).collect {|y| y}
      new_seasons=[]
      seasons.each do |x|
        season_fixup(x)
      end
      seasons.each do |x|
        case x
        when /\/(\d\d\d\d)\/.*\/Season(\d\d)/
          season=$2.to_i
          if programme_year==0
            year='filing'
          else
            begin
              case programme_name
              when "Have I Got News for You","Top Gear"
                year=programme_year+(season<2 ? 0 : (season/2)-1)
              else
                year=programme_year+(season<1 ? 0 : season-1)
              end
              raise YearOutOfBounds if year>2011
            rescue YearOutOfBounds
              season=season/10
              retry
            end
            new_seasons << x.gsub(/\/(\d\d\d\d)\//,"/#{year}/")
          end
        end
      end
      new_seasons.size.times do |x|
        next if seasons[x]==new_seasons[x]
        puts("Moving from #{seasons[x]} to #{new_seasons[x]}")
        FileUtils.mkdir_p(new_seasons[x])
        Dir.glob(File.join(seasons[x],'*')).each do |file|
          puts("Moving #{file}")
          begin
            FileUtils.mv(file,new_seasons[x])
          rescue
            Dir.glob(File.join(file,'*')).each do |subfile|
              puts("Moving #{subfile} to #{File.join(new_seasons[x],'.')}")
#              begin
#                FileUtils.mv(subfile,File.join(new_seasons[x],'.'))
#              end
            end
          end
        end
      end
    end
  end
end

ArchiveVideos::span_sources(VIDEO_SRC)