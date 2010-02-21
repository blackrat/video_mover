#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-10-28.
#  Copyright (c) 2006. All rights reserved.

class String
  def gsubx!(regex,replace)
    regex.each_with_index do |x,i|
      self.gsub!(x,replace[i])
    end
  end
  def gsubx(regex,replace)
    count=0
    str=self.dup
    regex.each_with_index do |x,i|
      str.gsub!(x,replace[i])
    end
  end
end
