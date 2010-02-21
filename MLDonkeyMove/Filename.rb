#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-10-28.
#  Copyright (c) 2006. All rights reserved.
require "logger"
logfile||="/var/log/maclog/#{0}.log"
begin
    Log||=Logger.new(logfile, shift_age='weekly')
rescue => e
    Log||=Logger.new(STDOUT)
    Log.error {e.message + ". Logging to stdout."}
end

VIDEOFILES=[".avi", ".mpg", ".ogm", ".swf", ".mpeg", ".vob", ".wmv", ".rm"]
AUDIOFILES=[".mp3", ".mp2"]
require "ftools"

class Filename
  attr_reader :directory, :filename, :extension, :fullname, :filetype
  attr_reader :video, :unknown

  def initialize(fullname)
    @directory=File.dirname(fullname)
    @filename=File.basename(fullname,'.*')
    @extension=File.extname(fullname)
    @fullname=fullname
    getfiletype(@extension)
  end

  def getfiletype(ext=@extension)
    @filetype=VIDEOFILES.include?(ext) ? :video : AUDIOFILES.include?(ext) ? :audio : :unknown
  end

  def setdirectory(dir)
    @directory=dir
    @fullname=File.join(@directory,@filename,@extension)
  end

  def moveto(directory=@directory,filename=@filename,extension=@extension)
    begin
      rc=false
	    File.makedirs(directory) unless File.exists?(directory)
	    dest=File.join(directory,filename+extension)
	    if ! File.exists?(dest) then
        begin
          Log.info {"Preparing to move #{fullname} to #{dest}."}
          File.move(fullname,dest)
          @directory=File.dirname(dest)
          @filename=File.basename(dest,'.*')
          @extension=File.extname(dest)
          @fullname=dest
          rc=true
        rescue => e
          Log.error {"#{e.message}. Error moving #{fullname} to #{dest}."}
        end
	    else
        Log.error {"#{dest} already exists. Cannot copy #{fullname}."}
	    end
    rescue => e
	    Log.error {"#{e.message}. Unable to make directory tree #{directory}."}
    end
    rc
  end

  def linkto(directory=@directory,filename=@filename,extension=@extension)
    begin
	    File.makedirs(directory) unless File.exists?(directory)
	    dest=File.join(directory,filename+extension)
	    if !File.exists?(dest) then
        begin
  		    Log.info {"Preparing to link #{fullname} to #{dest}."}
  		    File.symlink(File.expand_path(fullname),dest)
    		rescue => e
  		    Log.error {"#{e.message}. Unable to link #{fullname} to #{dest}."}
        end
	    else
        Log.error {"#{dest} already exists. Cannot copy #{fullname}."}
	    end
    rescue => e
	    Log.error {"#{e.message}. Unable to make directory tree #{directory}."}
    end
  end


  def normalize(a=@filename)
    a.downcase!
    a.gsub!(/[_\.-]/," ")
    a.gsub!(/(.*)\,\s*(a|the)\s*(.*)/i,'\2 \1 \3')
    while a.include?("  ")
      a.gsub!(/  /," ")
    end
    a.gsub!(/^ /,"")
    a.chomp!(" ")
    a.gsub!(/ /,"_")
    a.gsub!(/__/,"_")
    a
  end
end

class MLDonkeyFilename < Filename
  attr_reader :hash, :size, :video, :movie, :tv

  def initialize(md4hash,size,incoming_filename,incoming_directory="/var/lib/mldonkey/incoming/files")
    @hash=md4hash
  	@size=size
    super(File.join(incoming_directory,incoming_filename))
  end

  def getfiletype(ext=@extension)
  	super(ext)
  	if @filetype==:video then
	    if (@size.to_i > 700000000) then
    		@filetype=:movie
	    else
    		@filetype=:tv
	    end
  	end
  end
end
