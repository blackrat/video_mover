#!/usr/bin/env ruby
require 'fileutils'

module FileUtils

  MAPPING={ /PDF document/=>'pdf',
            /Matroska/=>'mkv',
            /iTunes AVC-LC/=>'mp4',
            /AVI/=>'avi',
            /directory/=>'',
            /^CDF/=>'cdf',
            /^XML/=>'xml',
            /^bzip2/=>'bz2',
            /^gzip/=>'gz',
            /^PE32/=>'exe',
            /^POSIX tar/=>'tar'
          }

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

FileUtils.getrealext("/Users/paul/Downloads/*").each do |x|
  puts(x.inspect)
end
