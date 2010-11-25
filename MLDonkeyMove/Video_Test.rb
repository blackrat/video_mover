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
				results=[]
				test_results=[]
				test.each do |y|
						dest=y[1]["dest"]
						testcase=TVEpisode.new(y[1]['src'],"extractdata")
						dest=File.join(testcase.auto_subdir,testcase.normalized_filename+testcase.extension)
						results << y[1]["dest"]
						test_results << dest
						assert_equal(y[1]["dest"],dest)
				end
    end
end
