#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-10-14.
#  Copyright (c) 2006. All rights reserved.

require "logger"
logfile||="/var/log/maclog/#{0}.log"
begin
  Log||=Logger.new(logfile, shift_age='weekly')
rescue => e
  Log||=Logger.new(STDOUT)
  Log.error { e.message + ". Logging to stdout." }
end

require "String.rb"
require "Filename.rb"
require "TitleCase.rb"

class String
  include TitleCase
end

#TODO: investigate folding everything to a .avi file, since mpeg and mpg files are subsets and .vob
#files are just .mpg files with a different name. MPlayer and Xine seem to treat them all properly.
#.swf and .rm files could cause a problem though

#Default arrays for substitution. Extraction of non-required phrases can be performed by passing in a file which
#contains a list of them, one line at a time, to the constructor. These are added to the find array with "_"
#prefixes and suffixes, and replaced with a single "_" on substitution.
$find_array   = [/\(/, /\)/, /'/, /$/, / & /, / s /, / m /, / t /, / ll /, /\[/, /\]/, /\,/]
$replace_array=[' ', ' ', ' ', ' ', ' and ', 's ', 'm ', 't ', 'll ', ' ', ' ', ' ']
$fixup_array  = [/\bregenesis\b/i, /\bxy\b/i, /\bcsi\b/i, /\bthe it\b/i, /\bnyc\b/i, /\bny\b/i, /\bsvu\b/i, /\btv\b/i, /\bbbc\b/i, /\busa\b/i, /\buk\b/i, /\bq.{0,1}i.{0,1}\b/i, /\bsnl\b/i, /\bsg.{0,1}1\b/i, /\bttr\b/i]
$fixedup_array=['ReGenesis', 'XY', 'CSI', 'The IT', 'New York City', 'New York', 'Special Victims Unit', 'TV', 'BBC', 'USA', 'UK', 'QI', 'Saturday Night Live', 'SG1', 'Tripping the Rift']
TVROOT        ="/vault/med01/video/episodes"
MOVIEROOT     ="/vault/med01/video/movies"
AUDIOROOT     ="/vault/med01/audio/radio/episodes"
TVALIAS       ="/pvr/A-Z"
MOVIEALIAS    ="/pvr/A-Z"
AUDIOALIAS    ="/par/A-Z"
LINKPATH      ="/pvr/new"
AUDIOLINK     ="/par/new"

class Video < Filename
  attr_reader :normalized_filename, :find_array, :replace_array, :auto_subdir, :base_dir, :link_dir, :alias_dir

  def initialize(fullname, extractfile="", findarray=$find_array, replacearray=$replace_array)
    super(fullname)
    @find_array   =findarray
    @replace_array=replacearray
    extractfile_include(extractfile) if extractfile != ""
    @normalized_filename=normalize(@filename)
    @auto_subdir        =""
    @base_dir           =""
    @link_dir           =LINKPATH
    @alias_dir          =""
  end

  def extractfile_include(extractfile)
    if File.exists?(extractfile) then
      File.open(extractfile) do |file|
        file.each do |line|
          name=Regexp.new('(\s|^)'+line.chomp.downcase+'(\s|$)')
          if !@find_array.include?(name) then
            @find_array.push(name)
            @replace_array.push(' ')
          end
        end
      end
    end
  end

  def normalize(a)
    a.downcase!
    a.gsub!(/[_\.-]/, " ")
    a.gsub!(/(.*)\,\s*(a|the)\s*(.*)/i, '\2 \1 \3')
    a.gsubx!(@find_array, @replace_array)
    a=a.titlecase
    a.gsubx!($fixup_array, $fixedup_array)
#    a.gsub!(/\s([a-z])/) {|x| x.upcase}
    while a.include?("  ")
      a.gsub!(/  /, " ")
    end
    a.gsub!(/^ /, "")
    a.chomp!(" ")
    a.gsub!(/ /, "_")
    a.gsub!(/__/, "_")
    a
  end

  def moveto(directory, filename="", auto_subdir="")
    destfile=@normalized_filename if filename==""
    @auto_subdir=auto_subdir unless auto_subdir==""
    if @auto_subdir!="" then
      directory   =File.join(directory, @auto_subdir)
      @auto_subdir=""
    end
    super(directory, destfile)
  end

  def linkto(directory, filename="")
    destfile=@normalized_filename if filename==""
    super(directory, destfile)
  end
end

class TVEpisode < Video
  attr_accessor :series, :season, :episode, :title

  def initialize(fullname, extractfile="")
    Log.info { "Beginning TVEpisode Initialization for #{fullname}." }
    super(fullname, extractfile)
    case @normalized_filename
      when /(.*?)_[s_#]*(\d{1,2}?)_*[ex]+_*(\d{1,2}|[a-zA-Z]{1,2})(.*)/i : #matches most cases
        @series =File.basename($1, '.*')
        @season =sprintf("%02d", $2.to_i)
        @episode=sprintf("%02d", $3.to_i)
        @title  =$4
      when /(.*?)[s_#](\d{1,2}?)_+[ex\.]*_*(\d{1,2})(.*)/i : #matches most cases
        @series =File.basename($1, '.*')
        @season =sprintf("%02d", $2.to_i)
        @episode=sprintf("%02d", $3.to_i)
        @title  =$4
      when /(.*?)_(\d*)[ep\.]*(\d{1,2})_*(.*)/ : #only a single number. Requires season
        @series=File.basename($1, '.*')
        @season=sprintf("%02d", $2.to_i)
        @season="01" if @season=="00"
        @episode=sprintf("%02d", $3.to_i)
        @title  =$4
      when /(.*?)_s(\d{1,2})_*(.*)/i : #only the Season. Requires episode
        @series =File.basename($1, '.*')
        @season =sprintf("%02d", $2.to_i)
        @episode="00"
        @title  =$3
      when /(.*?)_[s_#]*(\d{1,2}?)_*of_*(\d{1,2})(.*)/i : #matches most cases
        @series =File.basename($1, '.*')
        @season ="01"
        @episode=sprintf("%02d", $2.to_i)
        @title  ="_of_#{$3}_#{$4}"
#        when /(.*?)[s_#](\d{2})_*[ex\.]*_*(\d{2})(.*)/i:        #matches most cases
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=sprintf("%02d",$3.to_i)
#            @title=$4
#        when /(.*?)_(\d{1,2})x(.*?)_(.*)/:                     #only the season, unknown episode
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=$3
#            @title=$4
#        when /(.*?)_(\d{1,2})_(\d{1,2})_(.*)/:                  #space separated but watch out for Babylon 5, Blakes 7
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=sprintf("%02d",$3.to_i)
#            @title=$4
#        when /(.*?)_(\d{1,2})x([a-zA-Z]{2})(.*)/:               #only a single number. Requires season
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=sprintf("%02d",$3.to_i)
#            @title=$4
#        when /(.*?)_(\d{1,2}?)x*(\d\d)(.*)/:                    #triple number. Season 1 digit, episode 2
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=sprintf("%02d",$3.to_i)
#            @title=$4
#        when /(.*?)_(\d{1,2})(.*?)_(.*)/:
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode=$3
#            @title=$4
#        when /(.*?)_(\d{1,2})_(.*)/:
#            @series=File.basename($1,'.*')
#            @season=sprintf("%02d",$2.to_i)
#            @episode="00"
#            @title=$3
#        when /(.*?)_(\d{1,2})(.*)/:
#            @series=File.basename($1,'.*')
#            @season="01"
#            @episode=sprintf("%02d",$2.to_i)
#            @title=$3
      else
        @series =@normalized_filename
        @season ="00"
        @episode="00"
        @title  ="Episode_00"
    end
    @series.gsub!(/\d{4}/, '')
    @series=@series.gsub(/^_/, '').gsub(/_$/, '')
    @series.gsub!(/\d[ap]m/i) { |x| x.downcase }
    while @series.include?("__")
      @series.gsub!(/__/, "_")
    end
    @title=@title.gsub(/^_/, '').gsub(/_$/, '').gsub(/^[_\d]*[a-z]/) { |x| x.upcase }
    @title.gsub!(/\d[ap]m/i) { |x| x.downcase }
    @title="Episode_#{@episode}" if @title=="" or @title=="_"
    while @title.include?("__")
      @title.gsub!(/__/, "_")
    end
    @normalized_filename="#{@series}_#{@season}x#{@episode}_#{@title}"
    while @normalized_filename.include?("__")
      @normalized_filename.gsub!(/__/, "_")
    end
    @auto_subdir=File.join(@series, "Season#{@season}")
    @base_dir   =TVROOT
    @alias_dir  =TVALIAS
  end

  def normalize(a)
    Log.info { "Normalizing TVEpisode #{a}." }
    a=super(a)
    case a
#        when /(.*?)_[s_#]*(\d{1,2}?)_*[ex]+_*(\d{1,2}|[a-zA-Z]{1,2})(.*)/i:   #matches most cases
      when /(.*?)[s_#](\d{1,4}?)[ex\.]+(\d{1,4})(.*)/i : #matches most cases
        a="#{$1}_#{sprintf("%02d", $2.to_i)}x#{sprintf("%02d", $3.to_i)}_#{$4}".gsub(/__/, '_')
      when /[s_#]*(\d{1,4}?)[ex\.]+(\d{1,4})([^\d]*)(.*)/i : #match when started with the season
        a="#{$3}_#{sprintf("%02d", $1.to_i)}x#{sprintf("%02d", $2.to_i)}_#{$4}".gsub(/__/, '_')
      when /(.+?)[ex\.]+(\d{1,4})([^\d]*)(.*)/i : #match when started with the season
        a="#{$1}_01x#{sprintf("%02d", $2.to_i)}_#{$3}".gsub(/__/, '_')
      when /[ex\.]+(\d{1,4})([^\d]*)(.*)/i : #match when started with the season
        a="#{$2}_01x#{sprintf("%02d", $1.to_i)}_#{$3}".gsub(/__/, '_')
    end
    a=super(a)
    a
  end
end

class Audio < TVEpisode
  def initialize(fullname, extractfile="")
    super(fullname, extractfile)
    @base_dir =AUDIOROOT
    @alias_dir=AUDIOALIAS
  end

end

class Movie < Video
  attr_accessor :title

  def initialize(fullname, extractfile="")
    Log.info { "Beginning Movie Initialization for #{fullname}." }
    super(fullname, extractfile)
    @auto_subdir=@normalized_filename
    @auto_subdir=~/(.*)_[Cc][Dd]\d/
    @auto_subdir=$1 unless !$1
    @base_dir =MOVIEROOT
    @alias_dir=MOVIEALIAS
  end

  def normalize(a)
    Log.info { "Normalizing Movie #{a}." }
    a=super(a)
    a=~/(.*)_cd\d/i
    if $1 then
      a=$1
    end
    @filename=a
    a
  end
end
