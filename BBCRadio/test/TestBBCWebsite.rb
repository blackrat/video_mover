#!/usr/bin/env ruby
require 'test/unit'
require '../lib/BBCWebsite'

class TestBBCWebsite < Test::Unit::TestCase
  def test_initialize
    test=BBCWebsite.new
    assert_equal(test.url,"http://www.bbc.co.uk/radio/aod/index_noframes.shtml")
  end
  def test_fetch
    test=BBCWebsite.new
    name=test.fetch
    assert_equal name.class, Hash
    assert_equal 2, name.length
  end
  def test_network_list
    test=BBCWebsite.new
    name=test.networks
    assert_equal 18, name.length
  end
  def test_genre_list
    test=BBCWebsite.new
    name=test.genres
    assert_equal 24, name.length
  end
  def test_find_as_string
    test=BBCWebsite.new
    name=test.find("The Burkiss Way")
    assert_equal name.class, Hash
  end
end
