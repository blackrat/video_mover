#!/usr/bin/env ruby
require 'fileutils'

module FileUtils

  MAPPING={
            /Matroska/=>'mkv',
            /AVI/=>'avi',
            /directory/=>''}

  unless RUBY_PLATFORM=~/win[36]/
    def self.file(src)
      `file #{src}`.split("\n").collect {|x| x.split(":",2).collect {|y| y.strip}}
    end

    def self.getrealext(src)
      filelist=self.file(src)
      filelist.collect do |file_array|
        file_array+self.find_mapping(file_array[1])
      end
    end

    def self.find_mapping(file_type)
      MAPPING.each do |k,v|
        return [v] if file_type=~k
      end
      ['unknown']
    end
  end
end

p(FileUtils.getrealext("/vault/xen01/video/music/A/*"))
