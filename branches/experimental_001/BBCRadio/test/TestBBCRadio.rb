#!/usr/bin/env ruby
require 'test/unit'
require '../lib/BBCRadio'

class TestBBCRadio < Test::Unit::TestCase
  def test_initialize
    test=BBCRadio.new
    assert(!test.nil?)
  end

  def test_initialize_variable_directory
    test=BBCRadio.new(dir="~/borg")
    assert_equal test.dir, "~/borg"
  end

  def test_programmename
    test=BBCRadio.new
    name=test.programme_name(date="01/01/1970", time="00:00", channel="BBCOne")
    assert_equal name, "Unknown"
  end

  def test_programmename_real
    test=BBCRadio.new
    name=test.programme_name(date="16/05/2008", time="23:00", channel="BBCSeven")
    assert_equal name, "Brian_Appletons_History_of_Rock_and_Roll"
  end
end

