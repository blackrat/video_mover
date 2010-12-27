$:.unshift(File.join(File.dirname(__FILE__),'..','..','lib')) unless $:.include?(File.join(File.dirname(__FILE__),'..','..','lib'))
require 'rubygems'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require 'Config'
require 'String'

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
            return filename.gsub(le,v1) if filename=~le
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
        puts(e)
        nil
      end
    end


    def location(filename)
      file_type=type(filename)
      filename=normalize(filename,true)
      fileparts=filename.split('_',2)
      regular_expressions.each do |k,v|
        v.each do |reg|
          reg.each do |r1,v1|
            le=Regexp.new(r1,true)
            if filename=~le
              series_name,season,episode,title=$~[1..-1]
              prefix='filing'
              prefix=get_from_thetvdb($1)+$2.to_i unless $2.nil?
              return [prefix,$~[1..-1]].flatten
            end
          end
        end if k==file_type
      end
      [prefix,filename]
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
        if file_type==:unknown
          puts('break')
        end
        actual_ext=File.extname(filename)
        filename=File.basename(filename,actual_ext)
      end
      filename.downcase!
      filename.gsub!(/[_\.-]/," ")
      filename.gsub!(/(.*)\,\s*(a|the)\s*(.*)/i,'\2 \1 \3')
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