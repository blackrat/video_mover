#!/usr/bin/env ruby
require 'rubygems'
require 'spec'
$:.unshift('../lib')
require 'BBCWebsiteChannels'

BBC_NAME=:uk_bbc
BBC_URL="http://iplayerhelp.external.bbc.co.uk/help/streaming_programmes/real_wma_streams"

class Player
  attr_accessor :pthread
  def initialize
    @pthreads=[]
  end
  def play(name)
    mplayercommand="mplayer -prefer-ipv4 -noconsolecontrols -slave -vc null -vo null -bandwidth 99999999999 #{name} 2>&1"
    @pthreads << Thread.new { IO.popen "#{mplayercommand}",'r+'}
  end

  def stop
    @pthreads.each do |pthread|
      pthread.kill
      pthread.join
    end
  end
end

describe BBCWebsiteChannels do
  before :all do
    @test_obj=BBCWebsiteChannels.new(BBC_NAME)
  end

  it 'should error if initialized without a name' do
    lambda {BBCWebsiteChannels.new()}.should raise_error(ArgumentError)
  end

  it 'should error if initialized with a blank name' do
    lambda {BBCWebsiteChannels.new('')}.should raise_error(ArgumentError)
  end

  it 'should have a name' do
    @test_obj.name.should eql BBC_NAME
  end

  it 'should have an empty hash for channels to be setup if no valid BBC url is supplied' do
    @test_obj.channels.empty?.should eql true
  end

  it 'should allow for channels to be setup if a valid BBC url is supplied' do
    @test_obj2=BBCWebsiteChannels.new(BBC_NAME,BBC_URL)
    @test_obj2.channels.size.should > 1
  end

  it 'should allow for channels to be added if add is called with a valid BBC url and true' do
    @test_obj.add(BBC_URL,nil,true)
    @test_obj.channels.size.should > 1
  end

  it 'should have a collection of channels' do
    @test_obj.channels.class.should eql Hash
  end

end
