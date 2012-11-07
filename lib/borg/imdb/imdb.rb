#!/usr/bin/env ruby
require 'IMDBProgramme'

class IMDB
  attr_reader :id, :name, :seasons

  def initialize(name)
    @programme||=IMDBProgramme.new(name)
    @name     =@programme.name
    @id       =@programme.id
    @seasons  =@programme.seasons
  end

end
