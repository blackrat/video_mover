#!/usr/bin/env ruby
require 'rubygems'
require 'spec'
require 'yaml'
$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'IMDBWebPage'

describe IMDBWebPage, "when passed an invalid programme name" do
  before(:all) do
    @imdb=IMDBWebPage.new('not a recognized programme name from the search')
  end

  it "should not have a stored url" do
    @imdb.url.should eql(nil)
  end

  it "should have a failed search status" do
    @imdb.page_type.should eql(:failed_search)
  end

  it "should not have any info" do
    @imdb.info.should eql(nil)
  end
end

describe IMDBWebPage, "when passed an invalid but well formed url" do
  before(:all) do
    @imdb=IMDBWebPage.new('http://kasdasd.sdfafs.org')
  end

  it "should not have a stored url" do
    @imdb.url.should eql(nil)
  end

  it "should have a failed search status" do
    @imdb.page_type.should eql(:failed_search)
  end

  it "should not have any info" do
    @imdb.info.should eql(nil)
  end
end

describe IMDBWebPage, "when passed a person's name with no programme matches" do
  before(:all) do
    @imdb=IMDBWebPage.new('Paul McKibbin')
  end

  it "should not have a stored url" do
    @imdb.url.should eql(nil)
  end

  it "should not have info extracted from the webpage" do
    @imdb.info.should eql(nil)
  end

end

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


describe "valid movie search names", :shared=>true do
  it "should have a stored url equal to #{@url}" do
    @imdb.url.should eql(@url)
  end

  it "should have info extracted from the webpage" do
    @imdb.info.should_not eql(nil)
  end

  it "should have an id of #{@id}" do
    @imdb.info[:id].should eql(@id)
  end

  it "should not have an array of seasons" do
    @imdb.info[:seasons].should eql(nil)
  end
end


describe "valid search names", :shared=>true do
  it "should have a stored url" do
    @imdb.url.should eql(@url)
  end

  it "should have info extracted from the webpage" do
    @imdb.info.should_not eql(nil)
  end

  it "should have an id" do
    @imdb.info[:id].should eql(@id)
  end

  it "should have a hash of seasons" do
    @imdb.info[:seasons].should_not be_empty
    @imdb.info[:seasons].should be_a_kind_of(Hash)
  end

  it "should have an arrays of episodes in each season" do
    @imdb.info[:seasons].should include("Season#{@season}".to_sym)
    @imdb.info[:seasons]["Season#{@season}".to_sym].should be_a_kind_of(Array)
  end

  it "should have a precise episode" do
    @imdb.info[:seasons]["Season#{@season}".to_sym].should have_an_episode(@episode_hash)
  end
end

describe IMDBWebPage, "when passed an ambiguous programme name with a year in the title" do

  before(:all) do
    @name='Dr Who (1963)'
    @returned_name='Doctor Who (1963)'
    @id="tt0056751"
    @season=26
    @episode=14
    @episode_hash={:id=>"tt0811846",:season=>26,:episode=>14,:title=>"Survival: Part 3",:air_date=>"6 December 1989",:description=>nil }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed an ambiguous programme name" do

  before(:all) do
    @name='Dr Who'
    @returned_name='Doctor Who (2005)'
    @id="tt0436992"
    @season=4
    @episode=13
    @episode_hash={:id=>"tt1205438",:season=>@season,:episode=>@episode,:title=>"Journey's End",:air_date=> "5 July 2008",:description=>"In the wake of Davros' threat to destroy the existence of the Universe itself, the Doctor's companions unite to stop the Dalek empire. Which one will die by the prophecies and what will the fate be for the Doctor?" }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed an ambiguous programme name" do

  before(:all) do
    @name='Las Vegas'
    @returned_name='Las Vegas (2003)'
    @id="tt0364828"
    @season=5
    @episode=19
    @episode_hash={:id=>"tt1177591",:season=>5,:episode=>19,:title=>"Three Weddings and a Funeral: Part 2",:air_date=> "15 February 2008",:description=>"Mike's omission of his nuptials to his family prompts him to put together a wedding for his mother's sake, as well as his family, which prompts Danny to formerly propose to Dalinda. Sam's deceased ex-husband's brother shows up with plans to take ownership of the Montecito in his family's name." }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed an ambiguous programme name with an accurate year" do

  before(:all) do
    @name='Dr Who'
    @year=1963
    @returned_name='Doctor Who (1963)'
    @id="tt0056751"
    @season=26
    @episode=14
    @episode_hash={:id=>"tt0811846",:season=>26,:episode=>14,:title=>"Survival: Part 3",:air_date=>"6 December 1989",:description=>nil }
    @imdb=IMDBWebPage.new(@name,@year)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"
end

describe IMDBWebPage, "when passed an ambiguous programme name with an incorrect year which is close to the real one" do

  before(:all) do
    @name='Dr Who'
    @year=1962
    @returned_name='Doctor Who (1963)'
    @id="tt0056751"
    @season=26
    @episode=14
    @episode_hash={:id=>"tt0811846",:season=>26,:episode=>14,:title=>"Survival: Part 3",:air_date=>"6 December 1989",:description=>nil }
    @imdb=IMDBWebPage.new(@name,@year)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"
end

describe IMDBWebPage, "when passed an ambiguous programme name with an incorrect year which is more than 20 years away from the real one" do

  before(:all) do
    @name='Dr Who'
    @year=1902
    @returned_name='Doctor Who (2005)'
    @id="tt0436992"
    @season=4
    @episode=13
    @episode_hash={:id=>"tt1205438",:season=>4,:episode=>13,:title=>"Journey's End",:air_date=> "5 July 2008",:description=>"In the wake of Davros' threat to destroy the existence of the Universe itself, the Doctor's companions unite to stop the Dalek empire. Which one will die by the prophecies and what will the fate be for the Doctor?" }
    @episode="Doctor_Who_(2005)_04x13_Journey's_End"
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"
end

describe IMDBWebPage, "when passed a movie with a very common TV series name" do

  before(:all) do
    @name='The Kingdom'
    @returned_name='The Kingdom (2007)'
    @id="tt0431197"
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
    @season=nil
    @episode=nil
    @episode_hash=nil
  end

  it_should_behave_like "valid movie search names"
end

describe IMDBWebPage, "when passed an ambiguous programme name with no partial matches" do

  before(:all) do
    @name='House'
    @returned_name='House M D'
    @id="tt0412142"
    @season=4
    @episode=16
    @episode_hash={:id=>"tt1216109",:season=>4,:episode=>16,:title=>"Wilson's Heart",:air_date=> "19 May 2008",:description=>"The team works to cure Amber. The key to what ails her is inside House's head, but he was drunk when he noticed her symptoms." }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed an unambiguous programme name" do

  before(:all) do
    @name='Boston Legal'
    @returned_name='Boston Legal (2004)'
    @id="tt0402711"
    @season=4
    @episode=20
    @episode_hash={:id=>"tt0993809",:season=>4,:episode=>20,:title=>"Patriot Acts",:air_date=> "21 May 2008",:description=>"The town of Concord wishes to secede from the United States, and Alan and Denny act as opposing counsel in the case--a case that could cost them their friendship because their opposing views on patriotism and dissent." }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed an exact reference number" do

  before(:all) do
    @name='tt0402711'
    @returned_name='Boston Legal (2004)'
    @id="tt0402711"
    @season=4
    @episode=20
    @episode_hash={:id=>"tt0993809",:season=>4,:episode=>20,:title=>"Patriot Acts",:air_date=> "21 May 2008",:description=>"The town of Concord wishes to secede from the United States, and Alan and Denny act as opposing counsel in the case--a case that could cost them their friendship because their opposing views on patriotism and dissent." }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end


describe IMDBWebPage, "when passed an exact IMDB url" do

  before(:all) do
    @name='http://www.imdb.com/title/tt0863046/'
    @returned_name='The Flight of the Conchords (2007)'
    @id="tt0863046"
    @season=1
    @episode=12
    @episode_hash={:id=>"tt1078392",:season=>1,:episode=>12,:title=>"The Third Conchord",:air_date=> "2 September 2007",:description=>nil }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed a TV programme name which matches a film title name" do

  before(:all) do
    @name='Heartland'
    @returned_name='Heartland (2007/I)'
    @id="tt0839847"
    @season=1
    @episode=9
    @episode_hash={:id=>"tt1083655",:season=>1,:episode=>9,:title=>"Smile",:air_date=> "13 August 2007",:description=>"Nate grapples with Bart's death and how to write a eulogy for him; things get awkward between Tom and Kate." }
    @imdb=IMDBWebPage.new(@name)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

end

describe IMDBWebPage, "when passed a programme and a season number as a number" do

  before(:all) do
    @name='Las Vegas'
    @season=4
    @returned_name='Las Vegas (2003)'
    @id="tt0364828"
    @season=4
    @episode=17
    @episode_hash={:id=>"tt0954434",:season=>4,:episode=>17,:title=>"Heroes",:air_date=> "9 March 2007",:description=>"Jillian questions Ed's priorities when she finds out he's trying to purchase the Montecido. Delinda questions Danny's priorities when he's more caught up in trying to prevent a friend from being returned to Iraq than sitting down with her and finding out she's pregnant. Mike finds out Sam's plight, and Mary takes steps in helping her step-sisters' plight." }
    @imdb=IMDBWebPage.new(@name,@season)
    @url="http://www.imdb.com/title/#{@id}/"
  end

  it_should_behave_like "valid search names"

  it "should not include other seasons in its hash of seasons" do
    @imdb.info[:seasons].should_not include(:Season5)
    @imdb.info[:seasons].should_not include(:Season1)
    @imdb.info[:seasons].should_not include(:Season2)
    @imdb.info[:seasons].should_not include(:Season3)
  end

end
