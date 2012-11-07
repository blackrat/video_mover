#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require "open-uri"
require 'cgi'

CHANNELS     ={
  :bbc7   => { :name => 'bbc7', :display => 'BBC7' },
  :radio4 => { :name => 'radio4', :display => "Radio 4" }
}
NETWORK      ={ :network => "network", :genre => "genre" }
BBCROOT      ="http://www.bbc.co.uk"
NOFRAMESRADIO=""
class BBCWebsiteProgramme
  def initialize(name, url=nil)
    @name         =name
    @url          =url
    @description  =nil
    @original_name=nil
    @rtsp         =nil
  end

end
class BBCWebsiteChannel
  attr_reader :url

  def initialize(url="/radio/aod/networks/bbc7/audiolist.shtml")
    if url.include?("/")
      @url=url
    else
      res=nil
      CHANNELS.each { |k, v|
        v.each { |name, value|
          res=k if value==url or name==url.to_sym unless res
        }
      }
      if res.nil?
        @url="/radio/aod/networks/#{url}/audiolist.shtml"
      else
        @url="/radio/aod/networks/#{CHANNELS[res][:name]}/audiolist.shtml"
      end
    end
    @webpages=nil
  end

  def webpages
    fetch if @webpages.nil?
    @webpages
  end

  def fetch
    @webpages={ }
    doc      =Hpricot(open(BBCROOT+@url))
    (doc/"div#az//li").each { |e|
      description     =e.children.select { |ne| ne.text? }.join
      concatenate_name=false
      description     =description[3..-1]
      if description[0..3]=='...'
        concatenate_name=true
        description     =description[3..-1]
      end
#      multidates=(e/"//span")
      name    =nil
      datename=nil
      (e/"//a").each { |ne|
        url=ne.attributes['href']
        datename=ne.innerText if name
        name=ne.innerText unless name
        original_name=name
        if concatenate_name
          name       =name[0..-3]+description
          description=name
        end
        name=name.to_sym unless datename
        name="#{name}_#{datename}".to_sym if datename
        @webpages[name]                ={ }
        @webpages[name][:url]          =url
        @webpages[name][:text]         =description
        @webpages[name][:original_name]=original_name
        @webpages[name][:day]          =datename
        name                           =original_name
      }
    }
    @webpages
  end

  def programme(name)
    if webpages[name.to_sym].nil?
      raise "No such programme"
    else
      if webpages[name.to_sym][:rtsp].nil?
        base_programme              =webpages[name.to_sym]
        doc                         =Hpricot(open(BBCROOT+base_programme[:url]))
        rpm                         =(doc/"//embed").first.attributes['src']
        webpages[name.to_sym][:rtsp]=(open(BBCROOT+rpm) { |f| f.read }).gsub!(/\?BBC-UID.*/, "")
      end
      webpages[name.to_sym]
    end
  end

  def rtsp(name)
    programme(name)[:rtsp]
  end

  def list
    webpages.keys
  end

  def save(name, filename=nil, day=nil)
    if !filename
      tempfile=TempFile.new(['borg', 'wav'])
      filename=tempfile.path
      tempfile.close
      tempfile.unlink
    end
    mplayercommand="mplayer -prefer-ipv4 -vc null -vo null -bandwidth 99999999999 -ao pcm:fast -ao pcm:waveheader -ao pcm:file=\"#{filename}\" #{rtsp(name)}"
    `#{mplayercommand}`
    filename
  end

  def play(name)
    mplayercommand="mplayer -prefer-ipv4 -vc null -vo null -bandwidth 99999999999 #{rtsp(name)}"
    `#{mplayercommand}`
  end

  def find(name)
    self if programme(name)
  end
end

class BBCWebsite
  attr_reader :url

  def initialize(url="/radio/aod/index_noframes.shtml")
    @url=url
    @url=BBCROOT+@url unless @url.include?(BBCROOT)
    webpages=nil
  end

  def webpages
    fetch if @webpages.nil?
    @webpages
  end

  def fetch
    @webpages={ }
    doc      =Hpricot(open(@url))
    NETWORK.each { |k, v|
      @webpages[k]={ }
      (doc/"div##{v}//a").each { |e|
        @webpages[k][e.innerText.to_sym]=BBCWebsiteChannel.new(e.attributes['href']) #777-457-5462 - Tina
      }
    }
    @webpages
  end

  def networks
    webpages[:network]
  end

  def genres
    webpages[:genre]
  end

  def find(programme)
    res=nil
    networks.each { |k, v|
      begin
        res=v.find(programme)
      rescue
        nil
      end unless res
    }
    res
  end
end

