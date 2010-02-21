#!/usr/bin/env ruby
require 'rubygems'
require 'spec'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'IMDBProgramme'

class HaveAnEpisode
  def initialize(expected)
    @expected=expected
  end
  def matches?(target)
    @target=target
    @target.each { |t|
      return true if t==@expected
    }
    false
  end
  def failure_message
    "expected #{@target.inspect} to have an episode #{@expected.inspect}"
  end
  def negative_failure_message
    "expected #{@target.inspect} not to have an episode #{@expected.inspect}"
  end
end

def have_an_episode(expected)
  HaveAnEpisode.new(expected)
end



describe IMDBProgramme, "when passed an invalid programme name" do
  before(:all) do
    @IMDBProgramme=IMDBProgramme.new('not a recognized programme name from the search')
  end
  
  it "should not remember the programme name" do
    @IMDBProgramme.name.should eql(nil)
  end

  it "should not return a valid id" do
    @IMDBProgramme.id.should eql(nil)
  end
  
  it "should not return a list of seasons" do
    @IMDBProgramme.seasons.should eql(nil)
  end
  
end

describe IMDBProgramme, "when passed an unambiguous programme name" do
  before(:all) do
    @IMDBProgramme=IMDBProgramme.new("Burn Notice")
    @season=2
    @episode_hash={:title=>"Rough Seas", :season=>2, :episode=>7, :air_date=>"21 August 2008", :description=>"An early client of Michael's returns with a new job for him which will disrupt Fi's social life, and spark Madeline's, and the search for the buyer of the sniper rifle turns dangerous.", :id=>"tt1082945"}
  end

  it "should remember the expanded programme name" do
    @IMDBProgramme.name.should eql('Burn Notice (2007)')
  end
  
  it "should set the IMDBProgramme id to 'tt0810788'" do
    @IMDBProgramme.id.should eql("tt0810788")
  end
  

  it "should have a hash of seasons" do
    @IMDBProgramme.seasons.should_not be_empty
    @IMDBProgramme.seasons.should be_a_kind_of(Hash)
  end
  
  it "should have an arrays of seasons" do
    @IMDBProgramme.seasons.should include("Season#{@season}".to_sym)
    @IMDBProgramme.seasons["Season#{@season}".to_sym].should be_a_kind_of(Array)
  end

  it "should have a precise episode" do
    @IMDBProgramme.seasons["Season#{@season}".to_sym].should have_an_episode(@episode_hash)
  end  

end

describe IMDBProgramme, "when passed an ambiguous programme name" do
  before(:all) do
    @IMDBProgramme=IMDBProgramme.new("Dr Who (1963)")
    @season=26
    @episode_hash={:id=>"tt0811846",:season=>26,:episode=>14,:title=>"Survival: Part 3",:air_date=>"6 December 1989",:description=>nil }
  end

  it "should remember the first matching programme name" do
    @IMDBProgramme.name.should eql('Doctor Who (1963)')
  end
  
  it "should set the IMDBProgramme id to 'tt0056751'" do
    @IMDBProgramme.id.should eql("tt0056751")
  end

  it "should have a hash of seasons" do
    @IMDBProgramme.seasons.should_not be_empty
    @IMDBProgramme.seasons.should be_a_kind_of(Hash)
  end
  
  it "should have an arrays of episodes in each season" do
    @IMDBProgramme.seasons.should include("Season#{@season}".to_sym)
    @IMDBProgramme.seasons["Season#{@season}".to_sym].should be_a_kind_of(Array)
  end

  it "should have a precise episode" do
    @IMDBProgramme.seasons["Season#{@season}".to_sym].should have_an_episode(@episode_hash)
  end  

end

describe IMDBProgramme, "when passed a collection of names" do
  before(:all) do
    @names=Dir.entries('/vault/med01/video/episodes')
    @name=[]
    (rand(@names.size)).times { @name << @names[rand(@names.size)] }
    @names=@name.uniq[0..3]
  end
  
  it "should remember the matching programme names" do
    @names.each do |name|
      p name
      unless name[0]==46
        @IMDBProgramme=IMDBProgramme.new(name.gsub(/_/,' ')) unless name[0]==46
        p @IMDBProgramme.name
        p @IMDBProgramme.seasons
      end
    end
  end
end
