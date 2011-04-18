#!/usr/bin/env ruby
require 'rubygems'
require 'spec'
$:.unshift('../lib')
require 'BBCWebsiteChannel'

R7_URL="http://bbc.co.uk/radio/listen/live/r7.asx"

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

describe BBCWebsiteChannel do
  before :all do
    @test_obj=BBCWebsiteChannel.new(:bbcradio7)
  end
  
  it 'should have a name' do
    @test_obj.name.should eql :bbcradio7
  end
  
  it 'should have a url when a url is added' do
    @test_obj.add_urls(R7_URL)
    @test_obj.url.should eql R7_URL
  end

  it 'should NOT have a stream when a url is added and build is set to true' do
    @test_obj.add_urls(R7_URL)
    @test_obj.stream.should eql nil
  end
  
  it 'should have a stream when a url is added and build is set to true' do
    @test_obj.add_urls(R7_URL,true)
    @test_obj.stream.should_not eql nil
  end
  
  it 'should return the next stream when #stream(:next) is called' do
    @test_obj.add_urls(R7_URL,true)
    stream0=@test_obj.stream
    stream1=@test_obj.stream(:next)
    stream0.should_not eql stream1
  end
  
  it 'should return the previous stream when #stream(:prev) is called' do
    @test_obj.add_urls(R7_URL,true)
    stream0=@test_obj.stream
    stream1=@test_obj.stream(:prev)
    stream0.should_not eql stream1
  end

  it 'should play a stream when passed a player to the #play command' do
    @test_obj.add_urls(R7_URL,true)
    @player=Player.new
    @test_obj.play(@player)
    sleep 2
    @player.stop
  end
  
  it 'should play multiple streams when play is called multiple times' do
    @test_obj.add_urls(R7_URL,true)
    @player=Player.new
    @test_obj.play(@player)
    5.times do |x|
      @test_obj.stream(:next)
      @test_obj.play(@player)
    end
    sleep 2
    @player.stop    
  end

end
