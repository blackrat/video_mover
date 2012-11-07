#!usr/bin/env ruby
require 'IMDBWebPage'

class IMDBProgramme
  attr_reader :id, :name, :seasons, :episodes

  def initialize(name)
    @page||=IMDBWebPage.new(name)
    case @page.page_type
      when :unknown, :failed_search :
        @name=nil
        @page=nil
      when :root_page
        @name   =@page.info[:name]
        @id     =@page.info[:id]
        @seasons=@page.info[:seasons]
    end
  end

end
