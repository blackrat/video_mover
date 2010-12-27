#!/usr/bin/env rspec
require 'rubygems'
require 'rspec'
$:.unshift(File.join(File.dirname(__FILE__),'..','..','lib')) unless $:.include?(File.join(File.dirname(__FILE__),'..','..','lib'))
require 'config/Filename'

describe Filename do
  it 'should raise an argument error when #self.type is called with no arguments' do
    lambda {Filename.type()}.should raise_error ArgumentError
  end

  it 'should return :unknown when #self.type is called with an empty argument' do
    Filename.type('').should == :unknown
  end

  it 'should return :unknown when #self.type is called with an unknown file type extension' do
    Filename.type('broken.zzz').should == :unknown
  end

  it 'should return :audio when #self.type is called with an audio file type extension' do
    Filename.type('audio.mp3').should == :audio
  end

  it 'should return :video when #self.type is called with a video file type extension' do
    Filename.type('video.avi').should == :video
  end

  it 'should raise a Type error when initialized with an incompatible type' do
    lambda {Filename.new(nil)}.should raise_error TypeError
  end

  it 'should set #directory to "." when initialized with a empty filename' do
    @test_obj=Filename.new('')
    @test_obj.directory.should == '.'
  end

  it 'should set #extension to "" when initialized with a empty filename' do
    @test_obj=Filename.new('')
    @test_obj.extension.should == ''
  end

  it 'should set #filename to "" when initialized with a empty filename' do
    @test_obj=Filename.new('')
    @test_obj.filename.should == ''
  end

  it 'should set #filetype to :unknown when initialized with a empty filename' do
    @test_obj=Filename.new('')
    @test_obj.filetype.should == :unknown
  end

  it 'should set #fullname to :unknown when initialized with a empty filename' do
    @test_obj=Filename.new('')
    @test_obj.fullname.should == ''
  end

  it 'should set #filetype to :video when initialized with a video filename' do
    @test_obj=Filename.new('test.avi')
    @test_obj.filetype.should == :video
  end

  it 'should set #filetype to :audio when initialized with a video filename' do
    @test_obj=Filename.new('test.mp3')
    @test_obj.filetype.should == :audio
  end

  it 'should set #normalized_filename to "this_is_a_test" when initialized with a "This  .---...is-.-a.test..avi" filename' do
    @test_obj=Filename.new("This  .----...is-.-a.test..avi")
    @test_obj.normalized_filename.should == "this_is_a_test"
  end

  it 'should set #normalized_filename to "the_burkiss_way" when initialized with a "Burkiss way, the.avi" filename' do
    @test_obj=Filename.new("Burkiss way, the.avi")
    @test_obj.normalized_filename.should == "the_burkiss_way"
  end

end
