#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-10-28.
#  Copyright (c) 2006. All rights reserved.
# String utilities to add array substitution and titlecase
$:.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib')) unless $:.include?(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'TitleCase'

class String
  include TitleCase

  def gsubx!(regex, replace)
    regex.each_with_index do |x, i|
      self.gsub!(x, replace[i])
    end
  end

  def gsubx(regex, replace)
    count=0
    str  =self.dup
    regex.each_with_index do |x, i|
      str.gsub!(x, replace[i])
    end
  end
end
