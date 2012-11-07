#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'

IMDB_SEARCH  ="http://imdb.com/find?s=tt&q=%name"
IMDB_EPISODES="http://www.imdb.com/title/%id/episodes"
IMDB_TITLE   ="http://www.imdb.com/title/%id/"

class IMDB
  attr_reader :m_attributes
  attr_accessor :m_name

  def initialize (name)
    @attributes           ={ }
    @attributes[:name]    =name
    @attributes[:searched]=false
  end

  def name
    attributes[:name]
  end

  def normalize(a)
    a.downcase!
    a.gsub!(/[_\.-]/, " ")
    a.gsub!(/(.*)\,\s*(a|the)\s*(.*)/i, '\2 \1 \3')
    while a.include?("  ")
      a.gsub!(/  /, " ")
    end
    a.gsub!(/^ /, "")
    a.chomp!(" ")
    a.gsub!(/ /, "_")
    a.gsub!(/__/, "_")
    a
  end

  def id
    if attributes[:id].nil? then
      unless (attributes[:name].nil? or attributes[:searched]) then
        search
        begin
          attributes[:stats][:genre][:more]=~/tt\d*/
          attributes[:id]=$& if $&
        rescue
        end
      end
    end
    attributes[:id]
  end

  def episodes
    if attributes[:episodes].nil? then
      begin
        url                  =IMDB_EPISODES.gsub(/%id/, id)
        doc                  =Hpricot(open(url))
        attributes[:episodes]=extract_episodes(doc/"h4")
      end
    end
    attributes[:episodes]
  end

  def extract_episodes(elements)
    local_attributes={ }
    elements.each do |element|
      element.children.select { |e| e.text? }.to_s.strip=~/Season\s(\d*),\sEpisode\s(\d*):/
      season                         =sprintf("%02d", $1.to_i)
      episode                        =sprintf("%02d", $2.to_i)
      title                          =(element/:a).text
      fullname                       =normalize("#{attributes[:name]}_#{season}x#{episode}_#{title}")
      season                         ="Season#{season}"
      local_attributes[season.to_sym]||=[]
      local_attributes[season.to_sym] << fullname
    end
    local_attributes
  end

  def search
    attributes[:searched]=true
    begin
      doc=Hpricot(open(IMDB_SEARCH.gsub(/%name/, attributes[:name].gsub(/ /, "+"))))
      begin
        attributes[:stats]=extract_attributes(doc/".info")
      rescue
        begin
          link=(doc/'#outerbody tr td table tr td table tr td p table tr td')
          link=~/title.(tt\d{7})/
          doc               =Hpricot(open(IMDB_TITLE.gsub(/%id/, $1)))
          attributes[:stats]=extract_attributes(doc/".info")
        end
      end
    rescue
      $stderr.print "IMDB lookup failed"
    end
  end

  def extract_attributes(elements)
    local_attributes={ }
    elements.each do |element|
      attribute=((element/"h5").text.gsub(/[ :]/, "")).downcase
      attribute.gsub!(/\n.*\n/, "")
      unless attribute.empty? then
        attribute, elements        =expand_element(attribute.to_sym, element)
        local_attributes[attribute]=elements
      end
    end
    if local_attributes.nil? or local_attributes.empty? then
      throw
    else
      local_attributes
    end
  end

  def expand_element(attribute, elements)
    begin
      case attribute
        when :creator, :creators :
          expand_creator(elements)
        when :director, :directors :
          expand_director(elements)
        when :writer, :writers :
          expand_writer(elements)
        when :seasons, :season :
          [:seasons, expand_all(elements)]
        when :genre :
          [:genre, expand_all(elements)]
        when :tagline :
          [:tagline, expand_text(elements)]
        when :plot :
          [:plot, expand_text(elements)]
        when :plotkeywords :
          expand_plot_keywords(elements)
        when :awards :
          expand_awards(elements)
        when :newsdesk :
          expand_newsdesk(elements)
        when :usercomments :
          expand_user_comments(elements)
        when :runtime :
          expand_runtime(elements)
        when :country :
          expand_runtime(elements)
        when :language :
          expand_language(elements)
        when :color :
          expand_runtime(elements)
        when :aspectratio :
          expand_aspect_ration(elements)
        when :certification :
          expand_certification(elements)
        when :filminglocations :
          expand_filming_locations(elements)
        when :moviemeter :
          expand_moviemeter(elements)
        when :company :
          expand_company(elements)
        when :trivia :
          expand_trivia(elements)
        when :quotes :
          expand_quotes(elements)
        else
          p "Unknown attribute #{attribute} in #attributes[:name]"
      end
    rescue
    end
  end

  def expand_creator(elements)
    attributes       ={ }
    attributes[:name]=(elements/:a).first.inner_html
    attributes[:url] =(elements/:a).first[:href]
    return :creator, attributes
  end

  def expand_text(elements)
    attributes       ={ }
    attributes[:name]=elements.children.select { |e| e.text? }.to_s.strip
    attributes
  end

  def expand_first_link(elements)
    attributes                                       ={ }
    attributes[(elements/:a).first.inner_html.to_sym]=(elements/:a).first[:href]
    attributes
  end

  def expand_all(elements)
    attributes={ }
    (elements/:a).each do |element|
      attributes[element.inner_html.to_sym]=element[:href]
    end
    attributes
  end

end
