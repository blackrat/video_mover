#!/usr/bin/env ruby
require "ftools"
require "date"
require "rubygems"
require "zlib"
require 'yaml'
require 'DateRange'
require "archive/tar/minitar"
include Archive::Tar

TV_ANYTIME_DIR="~/.borg/TV_Anytime"
BBC_BACKSTAGE='http://backstage.bbc.co.uk/feeds/tvradio/#{date}.tar.gz'
TV_ANYTIME_NAMESPACE="urn:tva:metadata:2005"
TV_ANYTIME_TREE='//ScheduleEvent[PublishedStartTime=#{b_time}]/Program'
TV_ANYTIME_PROGRAM='//ProgramInformation[@programId=#{crid}]/BasicDescription'
CONFIG_FILE="borg.yaml"


class ConfigFile
  def self.tv_anytime (name)
    file=File.read(CONFIG_FILE)
    config_file=YAML.load(file)
    begin
      tv_anytime_name=config_file["config"]["channels"][name.downcase]["tv_anytime"]
    rescue
      name
    end
  end

  def self.radio_range
    file=File.read(CONFIG_FILE)
    config_file=YAML.load(file)
    channel_list=config_file["config"]["channels"].map { |names|
      names[1]["tv_anytime"]
    }
  end
end

class TV_Anytime
public
  def self.plindex(name,date)

  end


private
  def self.pl_lookup(docroot)
    pl_hash={}
    begin
      pl_hash[:crid]=docroot.elements["Program"].attributes['crid']
      duration=docroot.elements["PublishedDuration"].text
      pl_hash[:duration]=eval(duration[2..3])*60+eval(duration[5..6])
      starttime=docroot.elements["PublishedStartTime"].text
      pl_hash[:startdate]="#{starttime[0..3]}#{starttime[5..6]}#{starttime[8..9]}"
      pl_hash[:starttime]="#{starttime[11..12]}#{starttime[14..15]}"
    rescue
      pl_hash[:crid]||=nil
      pl_hash[:duration]||=0
      pl_hash[:startdate]||=nil
      pl_hash[:starttime]||=nil
    end
    pl_hash
  end

  def self.pi_lookup(docroot)
    pi_hash={}
    begin
      pi_hash[:crid]=docroot.attributes['programId']
      pi_hash[:name]=docroot.elements['BasicDescription/Title'].text
      pi_hash[:description]=docroot.elements['BasicDescription/Synopsis'].text
    rescue
      pi_hash[:name]||="Unknown"
      pi_hash[:description]||="Unknown"
      pi_hash[:crid]||=nil
    end
    pi_hash
  end

  def self.whenon(programme,range)
    programme_list=[]
    range.each do |date|
      datestring=date.strftime("%Y%m%d")
      rootdir=self.setup(datestring)
      ConfigFile.radio_range().each { |tvanytimename|
        pl_filename=File.join(rootdir,datestring+tvanytimename+"_pl.xml")
        pi_filename=File.join(rootdir,datestring+tvanytimename+"_pi.xml")
        if File.exist?(pl_filename) and File.exist?(pi_filename) then
          require 'rexml/document'
          pi_file=REXML::Document.new(File.open(pi_filename))
          pl_file=REXML::Document.new(File.open(pl_filename))
          begin
            pi_hash=pi_lookup(pi_file.elements["//ProgramInformation[contains(BasicDescription/Title,'"+programme+"')]"])
            combined_hash=pi_hash.merge(pl_lookup(pl_file.elements["//ScheduleEvent[Program[@crid='"+pi_hash[:crid]+"']]"]))
            combined_hash[:channel]=tvanytimename
            programme_list << combined_hash
          rescue
            nil
          end
        end
      }
    end
    if programme_list.length>0 then
      programme_list
    else
      nil
    end
  end

  def self.docroot_by_name(programme,pl_file)
    pl_file.elements["//ProgramInformation[contains(BasicDescription/Title,'"+programme+"')]"]
  end

public
  def self.setup(date=Time.now.localtime.strftime("%Y%m%d"))
    user_directory=File.expand_path(TV_ANYTIME_DIR)
    File.makedirs(user_directory) unless File.exists?(user_directory)
    end_date=Date.new(date[0..3].to_i,date[4..5].to_i,date[6..7].to_i)
    start_date=end_date-7
    (start_date..end_date).each do |new_date|
	 if File.exist?(File.join(user_directory,new_date.strftime("%Y%m%d"))) then
        return File.join(user_directory,new_date.strftime("%Y%m%d"))
	 end
    end
    today=Time.now.localtime.strftime("%Y%m%d")
    if date>today then
      date=today
    end
    if not File.exist?(File.join(user_directory,date+".tar.gz")) then
      require "open-uri"
      uri=eval('"' + BBC_BACKSTAGE + '"')
      open(uri) do |fin|
        open(File.join(user_directory,File.basename(uri)), 'w') do |fout|
          fout.write(fin.read)
        end
      end
    end
    if File.exist?(File.join(user_directory,date+".tar.gz")) then
      tgz = Zlib::GzipReader.new(File.open(File.join(user_directory,date+".tar.gz"), 'rb'))
	 Minitar.unpack(tgz, user_directory)
      return File.join(user_directory,date)
    end
  end

  def self.query(channel,date,time)
    rootdir=self.setup(date)
    tvanytimename=ConfigFile.tv_anytime(channel)
    combined_hash=nil
    pl_filename=File.join(rootdir,date+tvanytimename+"_pl.xml")
    pi_filename=File.join(rootdir,date+tvanytimename+"_pi.xml")
    b_time="#{date[0..3]}-#{date[4..5]}-#{date[6..7]}T#{time[0..1]}:#{time[2..3]}:00Z"
    if File.exist?(pl_filename) and File.exist?(pi_filename) then
      require 'rexml/document'
      pl_file=REXML::Document.new(File.open(pl_filename))
      pi_file=REXML::Document.new(File.open(pi_filename))
      begin
        pl_hash=pl_lookup(pl_file.elements["//ScheduleEvent[PublishedStartTime='"+b_time+"']"])
        pi_hash=pi_lookup(pi_file.elements["//ProgramInformation[@programId='"+pl_hash[:crid]+"']"])
        combined_hash=pi_hash.merge(pl_hash)
        combined_hash[:channel]=tvanytimename
        if [combined_hash[:crid]] then
          combined_hash
        else
          nil
        end
      rescue
        nil
      end
    end
    #if File.exist?(pl_filename) and File.exist?(pi_filename) then
    #  require 'rexml/document'
    #  pl_file=REXML::Document.new(File.open(pl_filename))
    #  begin
    #    crid=pl_file.elements["//ScheduleEvent[PublishedStartTime='"+b_time+"']/Program"].attributes['crid']
    #    duration=pl_file.elements["//ScheduleEvent[PublishedStartTime='"+b_time+"']/PublishedDuration"].text
    #    duration=eval(duration[2..3])*60+eval(duration[5..6])
    #    pi_file=REXML::Document.new(File.open(pi_filename))
    #    programme=pi_file.elements["//ProgramInformation[@programId='"+crid+"']/BasicDescription/Title"].text
    #    description=pi_file.elements["//ProgramInformation[@programId='"+crid+"']/BasicDescription/Synopsis"].text
    #  rescue
    #  end
    #end
    #return programme,description,duration
    combined_hash
  end


  def self.whatson(channel,date,time)
    self.query(channel,date,time)
  end

  def self.whenis(programme,offset=6)
    whenwas(programme,offset)
  end

  def self.whenwas(programme,offset=-6)
    nowdate=Time.now.localtime.strftime("%Y%m%d")
    base_date=Date.new(nowdate[0..3].to_i,nowdate[4..5].to_i,nowdate[6..7].to_i)
    if (offset<0) then
      start_date=base_date+offset
      end_date=base_date
    else
      start_date=base_date
      end_date=base_date+offset
    end
    whenon(programme,(start_date..end_date))
  end

  def self.whattimewas(date,programme)
    start_date=Date.new(date[0..3].to_i,date[4..5].to_i,date[6..7].to_i)
    end_date=start_date
    whenon(programme,(start_date..end_date))
  end

end


["20070811", "20070812"].each do |j|
  ["radio4","bbc7"].each do |k|
    ["0000","0030","1000","1015","1800","1815","2200","2230","2300","2400"].each do |i|
      puts TV_Anytime.whatson(k,j,i)
    end
  end
end

#["Dave Podmore", "Sorry"].each do |j|
#  puts TV_Anytime.whenwas(j)
#  puts TV_Anytime.whenis(j)
#end
