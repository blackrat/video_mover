#!/usr/bin/env ruby
require 'test/unit'
require '../lib/BBCWebsiteProgrammes'

class TestBBCWebsiteProgrammes < Test::Unit::TestCase
  def test_initialize_by_name
    test=BBCWebsiteProgrammes.new("The Burkiss Way")
    list=test.list
    assert_equal BBCWebsiteProgramme,list.class
    assert_equal 1,list.length
  end
end
