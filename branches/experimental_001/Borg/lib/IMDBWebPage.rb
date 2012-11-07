#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'
require 'fuzzy'
require 'fileutils'

IMDB_STORE     ="~/.borg/IMDB"
IMDB_ROOT      ="http://www.imdb.com"
IMDB_SEARCH    ="/find?s=tt&q=%name"
IMDB_EPISODES  ="episodes"
IMDB_TITLE     ="/title"
MATCHES        ={ :exact_matches   => { :name => "Titles (Exact Matches)", :value => 1 },
                  :popular_titles  => { :name => "Popular Titles", :value => 0 },
                  :partial_matches => { :name => "Titles (Partial Matches)", :value => 2 },
                  :approx_matches  => { :name => "Titles (Approx Matches)", :value => 3 }
}
PROGRAMME_TYPES={ :tv_series      => 0,
                  :tv_mini_series => 2,
                  :tv             => 3,
                  :movie          => 1
}


class String
  require 'uri'
  require 'TitleCase'
  include TitleCase

  def is_url?
    begin
      uri=URI.parse(self)
      if uri.class==URI::HTTP && (not self.grep(/^http:\/\/www.imdb.com\//).empty?)
        return true
      end
    rescue
      return false
    end
    false
  end
end

class IMDBWebPage
  attr_reader :page, :page_type, :url, :info, :year

  def initialize(url=nil, year=nil)
    FileUtils.mkdir_p(IMDB_STORE) unless File.exists?(IMDB_STORE)
    @supplied_name=url
    @year         =year
    @info         =nil
    @page_type    =:unknown
    if not url.nil?
      if url.is_url?
        @url=url
      else
        @year||= begin
          url[/[^\d]\d{4}[^\d]*$/][/\d{4}/].to_i rescue nil
        end
        if @year
          url.gsub!(/\s*[^\d]\d{4}[^\d]*$/, '')
        end
        @url=IMDB_ROOT+IMDB_SEARCH.gsub(/%name/, url.gsub(/\s/, '+'))
      end
      @url=nil unless @url.is_url?
    end
    @page=fetch unless @url.nil?
  end

  private
  def fetch
    fetch_web unless fetch_yaml
  end

  def fetch_yaml
    @info||=(File.exists?("#{File.expand_path(File.join(IMDB_STORE, @supplied_name))}.yml") ? open("#{File.expand_path(File.join(IMDB_STORE, @supplied_name))}.yml") { |f| YAML.load(f) } : nil) unless @supplied_name.nil?
    return nil if @info.nil? || begin
      ((Time.now-@info[:last_updated]).to_i) > (60*60*24*7) rescue nil
    end
    @info
  end

  def fetch_web
    doc=nil
    begin
      doc       =Hpricot(open(@url))
      @page_type=get_page_type(doc)
      case @page_type
        when :unknown, :failed_search :
          @url=nil
        when :ambiguous
          first_match=get_closest_match(doc)
          if first_match.nil?
            @page_type=:unknown
            @url      =nil
          else
            @url="#{IMDB_ROOT}#{first_match}"
            doc =@url.is_url? ? fetch_web : nil
          end
        when :root_page
          parse(doc)
          @info[:last_updated]=Time.now
          open("#{File.expand_path(File.join(IMDB_STORE, @supplied_name))}.yml", 'w') { |f| YAML.dump(@info, f) }
      end
    end
    doc
  end

  def get_closest_match(doc)
    links=get_all_programme_links(doc)
    if links.empty? and @year
      old_year=@year
      10.times do |year_offset|
        @year=@year+year_offset
        if @year < (Time.now.year+2)
          links=get_all_programme_links(doc)
          if !links.empty?
            return links[0][:link]
          end
        end
        @year=@year-year_offset
        if @year > 1850
          links=get_all_programme_links(doc)
          if !links.empty?
            return links[0][:link]
          end
        end
      end
      @year=nil
      links=get_all_programme_links(doc)
    end
    begin
      links[0][:link] rescue nil
    end
  end

  def get_all_programme_links(doc)
    programme_links=MATCHES.collect { |k, v| extract_list(doc, k) }
    rank_programme_links(programme_links)
  end

  def links_sort_order(x, y)
    difference=(x[:position]-y[:position]).abs
    cmp       = PROGRAMME_TYPES[x[:programme_type]] <=> PROGRAMME_TYPES[y[:programme_type]]
    if cmp!=0
      if difference<5
        return cmp
      end
    end
    cmp = MATCHES[x[:match_type]][:value] <=> MATCHES[y[:match_type]][:value]
    return cmp unless cmp==0
    calc=ZlibDistanceCalc.new
    calc.index(:root, @supplied_name)
    x_hash  =calc.search(x[:title])
    y_hash  =calc.search(y[:title])
    x_value = x_hash[:root].nil? ? 1 : x_hash[:root]
    y_value = y_hash[:root].nil? ? 1 : y_hash[:root]
    cmp     = x_value <=> y_value
    return cmp unless cmp==0
    cmp = y[:year] <=> x[:year]
    return cmp unless cmp==0
    x[:link]<=>y[:link]
  end

  def rank_programme_links(links)
    links.flatten!.compact!
    new_links=links.sort { |x, y|
      links_sort_order(x, y)
    }
    new_links
  end

  def extract_list(doc, search_string=:exact_matches)
    begin
      links   =doc.search("b[text()*=#{MATCHES[search_string][:name]}]").first.parent.search('//a[@href^="/title/"][@onclick=' ']')
      position=0
      links   =links.collect { |link|
        year          =link.parent.children.select { |e| e.text? }.to_s.strip.gsub(/[\(\)]/, '')
        href          =link[:href]
        title         =link.inner_text.gsub(/\"/, '')
        extra         =(link.parent/'small').inner_text
        search_text   =year + extra
        year          =year.gsub(/[^\d]*/, '')
        programme_type=case search_text
                         when /TV mini-series/ :
                           :tv_mini_series
                         when /TV series/ :
                           :tv_series
                         when /TV/ :
                           :tv
                         else
                           :movie
                       end
        position      =position+1
        if @year.nil? || @year.to_s==year
          { :link => href, :title => title, :year => year, :programme_type => programme_type, :match_type => search_string, :position => position }
        else
          nil
        end

      }
      links
    rescue
      nil
    end
  end

  def get_page_type(doc)
    return :failed_search unless (doc/"//b[text()*='No Matches']").empty?
    return :root_page unless (doc/".info").empty?
    return :ambiguous unless (doc/"#outerbody").empty?
    :unknown
  end

  def parse(doc)
    @info          =extract_attributes(doc/'.info')
    @info[:name]   =(doc/'meta[@name="title"]').first[:content].gsub(/[\'\"]/, '')
    @info[:id]     =get_id_from_info(@info)
    @url           ="#{IMDB_ROOT}#{IMDB_TITLE}/#{@info[:id]}/"
    @info[:seasons]=seasons
  end

  def get_id_from_info(info_hash)
    [:awards, :genre, :seasons, :company, :releasedate].each do |section|
      unless info_hash[section].nil?
        if info_hash[section][:more]
          info_hash[section][:more]=~/tt\d{7}/
          return $&
        end
      end
    end
    nil
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
      nil
    else
      local_attributes
    end
  end

  def expand_element(attribute, elements)
    begin
      case attribute
        when :creator, :creators :
          [:creator, expand_creator(elements)]
        when :director, :directors :
          [:director, expand_creator(elements)]
        when :writer, :writers :
          [:writer, expand_creator(elements)]
        when :seasons, :season :
          [:seasons, expand_all(elements)]
        when :parentsguide, :newsdesk, :genre, :plotkeywords, :awards, :usercomments, :country, :language, :color, :aspectratio, :certification, :filminglocations, :moviemeter, :company, :trivia, :goofs, :quotes, :releasedate, :alsoknownas, :soundmix, :movieconnections, :soundtrack :
          [attribute, expand_all(elements)]
        when :tagline, :plot, :runtime :
          [attribute, expand_text(elements)]
        else
          p "Unknown attribute #{attribute}"
          [attribute, expand_all(elements)]
      end
    rescue
    end
  end

  def expand_creator(elements)
    attributes       ={ }
    attributes[:name]=(elements/:a).first.inner_html
    attributes[:url] =(elements/:a).first[:href]
    attributes
  end

  def expand_text(elements)
    attributes       ={ }
    attributes[:name]=elements.children.select { |e| e.text? }.to_s.strip
    attributes
  end

  def expand_all(elements)
    attributes={ }
    (elements/:a).each do |element|
      attributes[element.inner_html.to_sym]=element[:href]
    end
    attributes
  end

  def seasons
    begin
      url=@url+IMDB_EPISODES
      doc=Hpricot(open(url))
      extract_seasons(doc/"h4")
    rescue
      nil
    end
  end

  def extract_seasons(elements)
    local_attributes={ }
    elements.each do |element|
      hash_elements={ }
      element.children.select { |e| e.text? }.to_s.strip=~/Season\s(\d*),\sEpisode\s(\d*):/
      hash_elements[:season] =$1.to_i
      hash_elements[:episode]=$2.to_i
      element.next_sibling.inner_text.strip=~/Original\sAir\sDate:\s(.*)$/
      hash_elements[:air_date]=$1
      (element/:a).first[:href]=~/tt\d{7}/
      hash_elements[:id]         =$&
      hash_elements[:title]      =(element/:a).text
      hash_elements[:description]=element.next_sibling.next_sibling.following.first.to_s.strip
      if hash_elements[:description].empty?
        hash_elements[:description]=nil
      end
      season                         ="Season#{hash_elements[:season]}"
      local_attributes[season.to_sym]||=[]
      local_attributes[season.to_sym] << hash_elements
    end
    local_attributes.empty? ? nil : local_attributes
  end

  def normalize(a)
    a.downcase!
    a.gsub!(/[_\.-]/, " ")
    a.gsub!(/:/, "")
    a.gsub!(/(.*)\,\s*(a|the)\s*(.*)/i, '\2 \1 \3')
    a=a.titlecase
    while a.include?("  ")
      a.gsub!(/  /, " ")
    end
    a.gsub!(/^ /, "")
    a.chomp!(" ")
    a.gsub!(/ /, "_")
    a.gsub!(/__/, "_")
    a
  end

  #    begin
  #      attributes[:stats]=extract_attributes(doc/".info")
end
