#!/usr/bin/env ruby
#Tests for Video.rb
Log=nil
require "Video"
require "rubygems"
require "Yaml"
require "test/unit"

class TestVideo < Test::Unit::TestCase

  def test_simple
    test=YAML.load(File.read('Video_Test.yml'))
    test.each do |y|
      src     =y[1]["src"]
      dest    =y[1]["dest"]
      testcase=TVEpisode.new(src, "extractdata")
      assert_equal(dest, File.join(testcase.auto_subdir, testcase.normalized_filename+testcase.extension))
    end
  end
end
