#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-12-03.
#  Copyright (c) 2006. All rights reserved.

AUDIO_BASE = "/vault/med01/par"
AUDIO_SRC  = ["/vault/med01/audio/radio/episodes", "/vault/med01/audio/albums"]
VIDEO_BASE = "/vault/med01/pvr"
VIDEO_SRC  = ["/vault/med01/video/movies", "/vault/med02/video/movies", "/vault/med01/video/episodes", "/vault/med02/video/episodes"]


require 'fileutils'
class Alphabetize
  public
  def self.rebuild(base_dir, src_dirs)
    base_dir=File.expand_path(base_dir)
    prepare(base_dir, src_dirs)
    move(base_dir, ["The", "A", "An"])
    move(base_dir)
    FileUtils.rm_r File.join(base_dir, "tmp") unless File.exists?(File.join(base_dir, "tmp", "*"))
  end

  private
  def self.prepare(base_dir, src_dirs)
    FileUtils.makedirs base_dir unless File.exist?(base_dir)
    ["tmp", "0-9", "A-I", "J-R", "S-Z"].each do |f|
      FileUtils.rm_r File.join(base_dir, f) if File.exist?(File.join(base_dir, f))
      FileUtils.makedirs File.join(base_dir, f)
    end
    dirlist=src_dirs.inject { |r, e| r+=","+e }
    Dir.glob("{#{dirlist}}/*").each do |i|
      begin
        FileUtils.ln_s i, File.join(base_dir, "tmp")
      rescue
#						begin
        FileUtils.ln_s i, File.join(base_dir, "tmp", File.basename(i)+"_The_Series")
#						rescue
#							puts "Error linking #{i} to #{File.join(base_dir,"tmp")}"
#						end
      end
    end
  end

  def self.move(base_dir, prefixes=nil)
    (('0'..'9').map + ('A'..'Z').map).each do |f|
      destdir=File.join base_dir, case f
                                    when '0'..'9' :
                                      "0-9"
                                    when 'A'..'I' :
                                      "A-I"
                                    when 'J'..'R' :
                                      "J-R"
                                    when 'S'..'Z' :
                                      "S-Z"
                                    else
                                      f
                                  end
      destdir=File.join destdir, case f
                                   when '0'..'9' :
                                     "0"
                                   else
                                     f
                                 end
      FileUtils.makedirs(destdir) unless File.exists?(destdir)
      if prefixes==nil then
        Dir.glob("#{File.join(base_dir, "tmp")}/{#{f}*}").each { |i| FileUtils.mv i, destdir unless not File.exists?(i) }
      else
        prefixes.each { |prefix|
          Dir.glob("#{File.join(base_dir, "tmp")}/{#{prefix}_#{f}*}").each { |i| FileUtils.mv i, destdir unless not File.exists?(i) }
        }
      end
    end
  end
end


Alphabetize.rebuild(VIDEO_BASE, VIDEO_SRC)
Alphabetize.rebuild(AUDIO_BASE, AUDIO_SRC)
