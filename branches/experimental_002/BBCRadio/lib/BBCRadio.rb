#!/usr/bin/env ruby
class BBCRadio
  attr_reader :dir

  def initialize(dir="~/.borg")
    @dir=dir
  end

  def programme_name(date, time, channel)
    if (date=="01/01/1970")
      return "Unknown"
    end
    "Brian_Appletons_History_of_Rock_and_Roll"
  end

  def fetch(date, time, channel)

  end
end
