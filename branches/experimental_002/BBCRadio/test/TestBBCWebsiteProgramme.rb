#!/usr/bin/env ruby
require 'test/unit'
require '../lib/BBCWebsiteProgramme'

class TestBBCWebsiteProgramme < Test::Unit::TestCase
  def test_initialize_by_url
    test=BBCWebsiteProgramme.new("/radio/aod/networks/1xtra/aod.shtml?1xtra/rnb1_mon")
    list=test.fetch
  end
end
