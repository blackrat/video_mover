#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-11-05.
#  Copyright (c) 2006-2012. All rights reserved.
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
LOG_DIR ='/var/log/video_mover'
LOG_FILE='video_mover.log'
require 'rubygems'
require "logger"
require 'video_mover'

begin
  FileUtils.mkdir_p(LOG_DIR) unless File.exists?(LOG_DIR)
  logfile=File.join(LOG_DIR, LOG_FILE)
  VideoMover.set_logger(Logger.new(logfile, shift_age='weekly'))
rescue => e
  VideoMover.logger.error { e.message + ". Logging to stdout." }
end

VideoMover.logger.info { "#{$0} starting." }
if ARGV.empty?
  VideoMover.logger.error { "No files specified. Exiting." }
else
  ARGV.each do |y|
    Dir.glob(y.gsub(/\[/, '\[').gsub(/\]/, '\]')).each do |x|
      filename=x.chomp
      filename=VideoMover.find_incoming(filename) unless File.exists?(filename)
      next if File.directory?(filename)
      if File.exists?(filename) then
        VideoMover.new(filename).move
      else
        VideoMover.logger.error { "Unable to find file #{filename}." }
      end
    end
  end
end
VideoMover.logger.info { "#{$0} completed." }
