#!/usr/bin/env ruby
class DateRange
  def DateRange.contains?(range, item)
    case range
      when "*" :
        true
      when item :
        true
      when "weekdays" :
        if item=="sun" or item=="sat" then
          false
        else
          true
        end
      when "weekends" :
        if item=="sun" or item=="sat" then
          true
        else
          false
        end
      else
        false
    end
  end

  def DateRange.index(day)
    ["sun", "mon", "tue", "wed", "thu", "fri", "sat"].index(day)
  end
end
