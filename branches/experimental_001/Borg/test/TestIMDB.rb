#!/usr/bin/env ruby
require 'test/unit'
require '../lib/IMDB'

class TestIMDB < Test::Unit::TestCase

  def test_initialize_blank
    test=IMDB.new()
    assert_equal(nil, test.name)
    assert_equal(nil, test.id)
  end

  def test_initialize_by_name
    test=IMDB.new("Burn Notice")
    assert_equal("Burn Notice", test.name)
    assert_equal("tt0810788", test.id)
  end

  def test_get_episodes
    test=IMDB.new("Burn Notice")
    assert_equal(2, test.episodes.length)
    assert_equal(12, test.episodes[:Season01].length)
    assert_equal(13, test.episodes[:Season02].length)
  end

  def test_get_episodes_non_unique
    test=IMDB.new("Dr Who")
    assert_equal(2, test.episodes.length)
    assert_equal(12, test.episodes[:Season01].length)
    assert_equal(13, test.episodes[:Season02].length)
  end

end
