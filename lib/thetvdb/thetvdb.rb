require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'common/config'

class String
  def url_encode
    gsub(/[^a-zA-Z0-9_\-.]/n){ sprintf("%%%02X", $&.unpack("C")[0]) }
  end
end

module TVDB
  class SeriesList < Array
    BASE="http://thetvdb.com/api/GetSeries.php?seriesname="
    attr_reader :name, :series

    def initialize(name)
      @name=name
      get_list
    end

    def get_list
      doc=Nokogiri::XML(open(BASE+@name.url_encode))
      doc.css("Data/Series").each {|x| self << Series.new(x)}
    end
  end

  class Series
    KEYS={:series_id=>["seriesid",:integer],:language=>"language",:name=>"SeriesName",:banner=>"banner",:overview=>"Overview",:first_aired=>["FirstAired",:date]}
    attr_reader *KEYS.keys

    def initialize(doc)
      KEYS.each do |key,value|
        value=case value
          when Array
            temp=doc.css(value[0]).text
            case value[1]
              when :integer
                begin
                  temp.to_i
                rescue
                  nil
                end
              when :date
                begin
                  Date.parse(temp)
                rescue
                  nil
                end
              else temp
            end
          else
            temp=doc.css(value).text
            temp.empty? ? nil : temp
          end
        instance_variable_set("@#{key.to_s}",value)
      end
    end
  end
end

test=TVDB::SeriesList.new('Supernatural')
test.each do |series|
  puts series.inspect
end
