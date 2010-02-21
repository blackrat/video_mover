#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'
require 'uri'

STATIONS='IRStations.yaml'

class IRStations
  attr_accessor :channels, :groups
  def initialize(file=STATIONS)
    load_groups(file)
  end
  
  def load_groups(file=STATIONS)
    @groups={}
    YAML::load(File.new(file)).each do |x|
      @groups[x]=channel_class_from_file(x)
    end
  end
  
  def channel_class_from_file(file)
    klass_group=nil
    group=YAML::load(File.new("#{file}.yaml"))
    begin
      require group[:class]
      klass_group=Module.const_get(group[:class]).new(file)
      if group[:urls].kind_of?(Hash)
        group[:urls].each do |k,v|
          klass_group.add(v,group[:channels],group[:channels].nil?)
        end
      else
        group[:urls].each do |v|
          klass_group.add(v,group[:channels],group[:channels].nil?)
        end
      end
    rescue NoMethodError=>e
      print("#{file}.yaml does not have the correct structure. Minimum structure required is:\n #{{:urls=>['url'],:class=>'processing_classname'}.to_yaml}\nSkipping.\n")
    rescue Exception=>e
      print("Error (#{e}) processing #{file}.yaml\nSkipping.\n")
    end
    klass_group
  end
  
  def build_groups()
    @groups.each do |x,y|
      begin
        require y[:class]
        @groups[x][:channels]=build_group(y)
      rescue
        print("Don't know what to do with #{x}")
      end
    end
  end
  
  def build_group(channel_def)
    channels={}
    channel_def[:urls].each do |x,y|
      channels.merge!(Module.const_get(channel_def[:class]).parse(y))
    end
    channels
  end
  
  def build_streams(url)
    uri=URI.parse(url)
    extension=File.extname(uri.path)
    case extension
    when ".asx"
      (Hpricot(open(url))/"ref").collect do |x|
        test=x.attributes['href']
        build_streams(test)
      end
    when ".ram"
      open(url) {|f| f.readlines}
    else
      url
    end
  end
  
  def parse(url)
    doc=Hpricot(open(url))
    channels={}
    confluence=doc/"td.confluenceTd/.."
    if confluence.empty?
      (doc/"#theContent//ul/li/a").each do |x|
        name=(x).innerText.gsub(/[\s-]/,'').gsub(/WMA/,'').downcase
        build(channels,name.to_sym,x.attributes['href']) if name=~/^[bbc|radio]/
      end
    else
      confluence.each do |y|
        begin
          (y/"td.confluenceTd").each_slice(2) do |x|
            name=x[0].innerText.gsub(/[\s-]/,'').gsub(/WMA/,'').downcase
            value=(x[1]/"//a").first.attributes['href']
            build(channels,name.to_sym,value) if name=~/^[bbc|radio]/
          end
        rescue
          next
        end
      end
    end
    channels
  end
  
  def save_groups(file=STATIONS)
    @groups.each do |k,v|
      File.open("#{k}.yaml",'w+') {|out|
        YAML::dump(v,out)
      }
    end
  end
end

test_obj=IRStations.new
test_obj.save_groups