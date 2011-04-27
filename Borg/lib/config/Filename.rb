$:.unshift(File.join(File.dirname(__FILE__),'..','..','lib')) unless $:.include?(File.join(File.dirname(__FILE__),'..','..','lib'))
require 'rubygems'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'Config'
require 'String'

VAULT_STORE = File.expand_path("~/.borg/first_aired")

class YearOutOfBounds < RuntimeError; end

class Filename
  include Config
  config :extensions, :regular_expressions, :extractions, :replacements, :fixups

  class << self
    def url_encode(s)
      s.to_s.gsub(/[^a-zA-Z0-9_\-.]/n){ sprintf("%%%02X", $&.unpack("C")[0]) }
    end

    def type(filename)
      extension=File.extname(filename)[1..-1]
      return :unknown if extension.nil? || extension.empty?
      extensions.each { |k,v|
        return k if v.include?(extension)
      }
      return :unknown
    end

    def do_replacements(filename)
      replacements.each do |k,v|
        filename.gsub!(Regexp.new('\b'+k+'\b'),v)
      end
      extractions.each do |k|
        filename.gsub!(Regexp.new('\b'+k+'\b'),' ')
      end
      filename
    end

    def do_fixups(filename)
      local_replacements={}
      fixups.each do |k,v|
        local_replacements[Regexp.new('\b'+k+'\b',true)]=v
      end
      local_replacements.each do |k,v|
        filename.gsub!(k,v)
      end
      filename
    end

    def parse(filename,file_type)
      regular_expressions.each do |k,v|
        v.each do |reg|
          reg.each do |r1,v1|
            le=Regexp.new(r1,true)
            if filename=~le
              Log.debug{"Matched #{filename} with #{le} replacing with #{v1}."}
              return filename.gsub(le,v1)
            end
          end
        end if k==file_type
      end
      filename
    end

    def get_from_thetvdb(name)
      begin
        doc = Nokogiri::XML(open("http://thetvdb.com/api/GetSeries.php?seriesname=#{url_encode(name)}"))
        year=(doc.css("Data/Series/FirstAired").text).split('-')[0].to_i
        year
      rescue Exception=>e
        Log.error(e)
        nil
      end
    end


    def save_to_file
      spool_hash=YAML.load_file(VAULT_STORE)
      spool_hash.merge!(@programme_hash)
      File.open(VAULT_STORE,'w') {|fd| YAML.dump(spool_hash,fd)}
    end

    def get_from_file(name)
      begin
        details=YAML.load_file(VAULT_STORE)
        details[name]
      rescue Exception=>e
        Log.error(e)
        nil
      end
    end

    def programme_find_year(programme_name)
      @programme_hash||=Hash.new do |first_aired,name|
        spool=false
        val=get_from_file(name)
        if val.nil?
          val=get_from_thetvdb(name)
          spool=true
        end
        first_aired[name]=val
        save_to_file if spool
        val
      end
      @programme_hash[programme_name]
    end

    def get_year(series_name,season)
      unless season.nil?
        base_year=programme_find_year(series_name)
        if base_year > 1800
          prefix=[Time.now.year, base_year + ((season.to_i>1) ? season.to_i-1 : 0)].min
          Log.debug{"Setting #{series_name} Season #{season} year to #{prefix}."}
          prefix
        else
          Log.error{"Unable to find a recent match for #{series_name}."}
          nil
        end
      end
    end

    def location(filename)
      file_type=type(filename)
      filename=normalize(filename,true)
      regular_expressions.each do |k,v|
        if k==file_type
          v.each do |reg|
            reg.each do |r1, v1|
              le=Regexp.new(r1, true)
              if filename=~le
                Log.debug{"Matched using regular expression (#{r1})."}
                return [get_year($1,$2),$~[1..-1]].flatten
              end
            end
          end
        end
      end
      Log.error{"Unable to find a pattern match for #{filename}"}
      [nil,filename]
    end

    def pre_titlecase(filename)
      do_replacements(filename)
    end

    def post_titlecase(filename)
      do_fixups(filename)
    end

    def normalize(filename,ext=false)
      actual_ext=''
      file_type=:unknown
      if ext
        file_type=type(filename)
        actual_ext=File.extname(filename)
        filename=File.basename(filename,actual_ext)
      end
      filename.downcase!
      filename.gsub!(/[_\.-]/," ")
      filename.gsub!(/(.*)\,\s*(a|the)[\s_](.*)/i,'\2 \1 \3')
      filename=pre_titlecase(filename)
      filename=filename.titlecase
      filename=post_titlecase(filename)
      while filename.include?("  ")
        filename.gsub!(/  /," ")
      end
      filename.gsub!(/^ /,"")
      filename.chomp!(" ")
      filename.gsub!(/ /,"_")
      filename.gsub!(/__/,"_")
      filename=parse(filename,file_type)
      filename+=actual_ext if ext
      filename
    end
  end

  attr_reader :directory, :filename, :extension, :fullname, :filetype, :normalized_filename

  def initialize(fullname)
    @fullname=fullname
    @directory=File.dirname(@fullname)
    @filename=File.basename(@fullname,'.*')
    @extension=File.extname(@fullname)
    @filetype=Filename.type(@fullname)
    @normalized_filename=Filename.normalize(@filename)
  end
end