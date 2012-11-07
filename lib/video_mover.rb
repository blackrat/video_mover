require File.join(File.dirname(__FILE__), 'borg')
require 'logger'

class VideoMover
  include Borg::Config
  config :borg_params

  class << self
    attr_accessor :logger

    def set_logger(log)
      @logger=log
    end

    def find_incoming(filename)
      borg_params[:incoming].each do |incoming_dir|
        return File.join(incoming_dir, filename) if File.exists?(File.join(incoming_dir, filename))
      end
      filename
    end

    def log
      @logger||=Logger.new(STDOUT)
    end
  end

  def log
    self.class.log
  end

  def initialize(filename)
    log.info { "Analysing #{filename}." }
    @filename                                     =filename
    @year, @series_name, @season, @episode, @title=Filename::location(filename)
  end

  def for_all_destinations(&blk)
    self.class.borg_params[:destinations].each do |directory|
      yield directory
    end
  end

  def first_destination_matching(*arr)
    for_all_destinations do |directory|
      dir_to_check=File.join(directory, arr)
      return dir_to_check if File.exists?(dir_to_check)
    end
    nil
  end

  def series_directory
    first_destination_matching(@series_name)
  end

  def series_in_year
    first_destination_matching(@year.to_s, @series_name)
  end

  def broadcast_year
    first_destination_matching(@year.to_s)
  end

  def default_directory
    root=first_destination_matching
    root && File.join(root, @series_name)
  end

  def actual_directory
    #series_directory || series_in_year || broadcast_year || default_directory
    series_directory || default_directory
  end

  def destination_directory
    @destination_directory||=actual_directory
  end

  def pad_integer(value)
    begin
      "%02d" % value.to_i
    rescue
      "00"
    end
  end

  def season
    pad_integer(@season)
  end

  def episode
    pad_integer(@episode)
  end

  def move
    if @year || (try_directory_name && @year)
      location=@episode.nil? ? destination_directory : File.join(destination_directory, "Season#{season}")
      move_to(File.join(location, "#{@series_name}_#{season}x#{episode}_#{@title}")) if create_directory(location)
    else
      log.error { "Unable to determine series details for #{@filename}." }
    end
  end

  def try_directory_name
    extension                                     =File.extname(@filename)
    file_parts                                    =@filename.split(/\//)
    filename                                      =File.join(file_parts[0..-2], "#{file_parts[-2]}#{extension}")
    @year, @series_name, @season, @episode, @title=Filename::location(filename)
  end

  def touch_tree(series_dirname)
    tree =series_dirname.split('/')
    parts=tree.size-1
    parts.times do |count|
      file_dirname=File.join(tree[0..count+1])
      FileUtils.touch(file_dirname)
    end
  end

  def create_directory(series_dirname)
    unless File.exists?(series_dirname)
      log.debug { "Creating series directory #{series_dirname}." }
      begin
        FileUtils.mkdir_p(series_dirname)
      rescue
        log.error { "Failed to create series directory #{series_dirname}." }
        return false
      end
    else
      log.debug { "Series directory #{series_dirname} already exists." }
    end
    true
  end

  def move_to(destination)
    unless File.exists?(destination)
      log.info { "Moving #{@filename} to #{destination}." }
      FileUtils.mv(@filename, destination)
      touch_tree(destination)
    else
      log.error { "#{destination} already exists. Not moving #{@filename}." }
    end
  end

end
