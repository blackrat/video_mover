#!/usr/bin/env spec
require 'rubygems'
require 'spec'
$:.unshift('../lib')
require 'IRStations'

describe IRStations do
  before :all do
    @test_obj=IRStations.new
  end
  
  it 'should have an array of groups' do
    @test_obj.groups.class.should eql Array
  end
end

