#!/usr/bin/env ruby
require "mysql"
require "logger"
require "Filename"
require "Video"

class MythFilename < Filename
  attr_reader :size, :video, :movie, :tv
  def initialize(size,incoming_filename,incoming_directory="/mythtv/recordings")
    @size=size
    super(File.join(incoming_directory,incoming_filename))
  end
  def getfiletype(ext=@extension)
    super(ext)
    if @filetype==:video
      if (@size.to_i > 400000000) then
        @filetype=:movie
      else
        @filetype=:tv
      end
    end
  end
end 


SRC_DIR="/mythtv/recordings"
DST_DIR="/vault/med01/episodes"
LOG_FILE="/var/log/mythtv/mythmove.log"
EXTRACT_FILE="/etc/extractdata"

logfile=File.expand_path(LOG_FILE)
Log=Logger.new(logfile, shift_age='weekly')
Log.info "#{$0} starting."

begin
    # connect to the MySQL server
    dbh = Mysql.real_connect("pvr03", "mythtv", "dundftab", "mythconverg")
    # get server version string and display it
    puts "Server version: " + dbh.get_server_info
    res = dbh.query("select title, subtitle, filesize, programid, seriesid, basename from recorded")
    res.each do |row|
        title, subtitle, size, programid, seriesid, src=row
        srcfile=File.join(SRC_DIR,src)
        destfile=File.join(DST_DIR,title,"Recording","#{title}_00x00_#{subtitle}_#{programid}_#{seriesid}.avi")
#       if File.exists?(File.join(srcfile)) then
            Log.info "Analysing #{src}."
            extractfile=File.expand_path(EXTRACT_FILE)
            myth_file=MythFilename.new(size,src,SRC_DIR)
            src=Video.new(srcfile)
            dest=case myth_file.filetype
                when :tv:
                    TVEpisode.new(destfile,extractfile)
                when :video:
                    Video.new(destfile,extractfile)
                when :movie:
                    Movie.new(destfile,extractfile)
            else
                Log.warn "Error determining file type #{myth_file.filetype}."
            end
            Log.info "Preparing to move #{src.filename} to " + File.join(dest.base_dir,dest.normalized_filename+dest.extension) + "."    
            src.moveto(dest.base_dir,dest.normalized_filename,dest.auto_subdir)
#        end
    end    
rescue Mysql::Error => e
    puts "Error code: #{e.errno}"
    puts "Error message: #{e.error}"
    puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
    # disconnect from server
    dbh.close if dbh
end
