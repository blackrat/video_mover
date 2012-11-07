#!/usr/bin/env ruby

require "logger"
logfile||="/var/log/borglog/#{0}.log"
begin
  Log=Logger.new(logfile, shift_age='weekly')
rescue => e
  Log=Logger.new(STDOUT)
  Log.error { e.message + ". Logging to stdout." }
end

ROOT_DIR   ="~/audio/test/"
WAV_DIR    ="#{ROOT_DIR}episodes"
MP3_DIR    =WAV_DIR
CHK_DIR    ="#{ROOT_DIR}check"
GUIDE_DIR  ="#{ROOT_DIR}guide"
RADIO4     ="bbc_radio4"
BBC7       ="bbc7"
LOG        ="/var/log/#{File.basename($0, '.rb')}.log"
LOCK       ="/var/run/borg/bbccomedy.lck"
CONFIG_FILE="borg.yaml"

require 'ftools'
require 'BBCWebsite'
require 'DateRange'

class Radio
  def initialize(config_file)
    @schedule||=[]
    @channels=config_file["config"]["channels"]
    @exclude =config_file["exclude"]
    ["sun", "mon", "tue", "wed", "thu", "fri", "sat"].each do |day|
      @channels.each do |channel, data|
        schedule_include(config_file["include"]["*"], channel, day)
        schedule_include(config_file["include"][channel], channel, day)
      end
    end
  end

  def schedule_include(root, channel, day)
    if root then
      root.each do |date, value|
        value.each do |time, programme|
          if DateRange.contains?(date, day) then
            schedule_add(channel, day, time.to_s, programme)
          end
        end
      end
    end
  end

  def schedule_add(channel, date, time, programme="*")
    localdate=(DateTime::now()+((DateRange.index(date)-6-DateTime::now().wday)%-7)-1).strftime("%Y%m%d")
    if time=="*" then
      programme.each do |programme_name|
        programme_list=schedule_getprogrammes_on_date(programme_name, localdate)
        if programme_list then
          programme_list.each do |item|
            @schedule << item
          end
        end
      end
    else
      localtime=time
      if Time.local(localdate[0..3], localdate[4..5], localdate[6..7]).isdst then
        if localtime=="0000"
          localtime="2300"
          localdate=(DateTime::now()+((DateRange.index(date)-6-DateTime::now().wday)%-7)-2).strftime("%Y%m%d")
        else
          localtime="%04d" % (localtime.to_i-100)
        end
      end
      item=schedule_getname(channel, localdate, localtime)
      @schedule << item if item
    end
  end

  def record_all()
    @schedule.each { |item|
      puts item[:startdate]
      puts item[:starttime]
      puts item[:duration]
    }
    start_date=DateTime::now()-7
    end_date  =DateTime::now()-1
    (start_date..end_date).each do |air_date|
      date_stamp =air_date.strftime("%Y%m%d")
      day_of_week=Date::DAYNAMES[air_date.wday]
      Log.info { "Recording #{date_stamp} radio programmes." }
    end
  end

  def schedule_getname(channel, date, time)
    require 'TV_Anytime'
    TV_Anytime.whatson(channel, date, time)
  end

  def schedule_getprogrammes(name)
    require 'TV_Anytime'
    TV_Anytime.whenwas(name)
  end

  def schedule_getprogrammes_on_date(name, date)
    require 'TV_Anytime'
    TV_Anytime.whattimewas(date, name)
  end

  def record()
  end
end

def main
  require 'yaml'
  begin
    [ROOT_DIR, WAV_DIR, MP3_DIR, CHK_DIR, GUIDE_DIR].each do |dir|
      File.makedirs(dir) unless File.exists?(dir)
    end
    config_file=YAML.load(File.read(CONFIG_FILE))
    rad        =Radio.new(config_file)
    rad.record_all
  rescue ArgumentError => e
    Log.error { "#{CONFIG_FILE} contains errors. #{e.message}." }
  rescue => e
    Log.error { "#{e.message}." }
  end
end

if File.exists?(LOCK) then
  Log.error { "Lockfile exists. If this is the only instance you need to delete #{LOCK} to continue" }
else
  begin
    lock=Logger.new(LOCK)
    lock.info("Lock")
    lock_file=true
  rescue
    lock=Logger.new(STDOUT)
    msg ="Unable to create Lockfile #{LOCK}. Continuing without locking."
    lock.error { msg }
    Log.error { msg }
    lock_file=false
  end
  Log.info { "#{$0} starting." }

  #TODO - Write application
  main()

  Log.info { "#{$0} ending." }
  lock.close unless not lock_file
  File.delete(LOCK) unless not lock_file
end
