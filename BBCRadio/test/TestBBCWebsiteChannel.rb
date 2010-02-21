#!/usr/bin/env ruby
require 'test/unit'
require '../lib/BBCWebsiteChannel'

class TestBBCWebsiteChannel < Test::Unit::TestCase
  def test_initialize
    test=BBCWebsiteChannel.new("bbc7")
    assert_equal("/radio/aod/networks/bbc7/audiolist.shtml",test.url)
  end
  def test_fetch
    test=BBCWebsiteChannel.new("bbc7")
    name=test.fetch
    assert_equal name.class, Hash
    assert (20..246).include?(name.length)
  end
  def test_list
    test=BBCWebsiteChannel.new("Radio 4")
    names=test.list
    puts(names)
    assert_equal Array, names.class
    assert (20..246).include?(name.length)
  end
  def test_channel_by_name
    test=BBCWebsiteChannel.new("Radio 4")
    assert_equal("/radio/aod/networks/radio4/audiolist.shtml",test.url)
  end
  def test_programme
    test=BBCWebsiteChannel.new("bbc7")
    name=test.programme("The Burkiss Way")
    assert_equal Hash,name.class
    assert_equal "Bruce's Choice and Start New Series the Burkiss Way.",name[:text]
    assert_equal "rtsp://rmv8.bbc.net.uk/bbc7/1230_thu.ra",name[:rtsp]
  end
  def test_rtsp
    test=BBCWebsiteChannel.new("bbc7")
    name=test.rtsp("The Burkiss Way")
    assert_equal "rtsp://rmv8.bbc.net.uk/bbc7/1230_thu.ra",name    
  end
  def test_save_nooverwrite
    filename="The_Beaded_Ladies.wav"
    `touch #{filename}`
    test=BBCWebsiteChannel.new("bbc7")
#    assert_raise RuntimeError do
#      test.save("The Bearded Ladies",filename)
#    end
  end
  def test_save
    filename="The_Bearded_Ladies.wav"
    `rm #{filename}`
    test=BBCWebsiteChannel.new("bbc7")
    name=test.save("The Bearded Ladies","The_Bearded_Ladies.wav")
    assert_match filename, File::basename(filename)
  end
  def test_play
    test=BBCWebsiteChannel.new("bbc7")
#    name=test.play("The Burkiss Way")        
  end
  def test_find_as_string
    test=BBCWebsiteChannel.new("bbc7")
    name=test.find("The Burkiss Way")
    assert_equal name.class, Hash
    assert_equal name[:original_name],"The Burkiss Way"
    assert_equal name[:rtsp],"rtsp://rmv8.bbc.net.uk/bbc7/1230_thu.ra"
  end
  def test_find_as_regexp
    test=BBCWebsiteChannel.new("bbc7")
    name=test.find(/Burkiss/)
    assert_equal name.class, Hash
    assert_equal name[:original_name],"The Burkiss Way"
    assert_equal name[:rtsp],"rtsp://rmv8.bbc.net.uk/bbc7/1230_thu.ra"
  end
end
