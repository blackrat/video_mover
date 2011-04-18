#!/usr/bin/env ruby
require 'zlib'

# this is optimized to store a relatively smaller subset of common index
# terms against which new strings should be tested
class ZlibDistanceCalc
  def initialize
    @c_hash = Hash.new
  end

  def index(key, term)
    @c_hash[key] = [term, compress(term)]
  end

  def test(term)
    coeff = term.size.to_f

    results = {}

    @c_hash.each do |k,v|
      orig_str, orig_cmp = v

      delta = (compress(orig_str + term).size - orig_cmp.size) / coeff
      results[k] = delta
    end

    return results
  end

  def search(term, delta=0.5)
    test_results = Hash[*test(term).select {|k,v| v <= delta }.flatten]

    if block_given?
      test_results.each {|k,v| yield k, v }
    else
      return test_results
    end
  end

  def compress(term)
    Zlib::Deflate.deflate(term.strip.downcase)
  end
end