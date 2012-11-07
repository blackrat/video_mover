#!/usr/bin/env ruby
TESTS=[{ :name => 'Dr Who', :returned_name => 'Doctor Who (1963)', :id => 'tt0056751', :season => :Season26, :episode => 'Doctor_Who_(1963)_26x14_Survival_Part_3' },
       { :name => 'Boston Legal', :returned_name => 'Doctor Who (1963)', :id => 'tt0056751', :season => :Season26, :episode => 'Doctor_Who_(1963)_26x14_Survival_Part_3' }]

require 'yaml'

File.open('fixtures.yml', 'w') { |f| f.puts TESTS.to_yaml }

