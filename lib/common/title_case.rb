#!/usr/bin/env ruby
# Semiintelligent title-casing
#
# Author: Martin DeMello <martindemello@yahoo.com>
# Date: Jan 07, 2003
#
# Thanks to Janet Miles for help with the capitalization rules
#
# Reference: The Harbrace Handbook
#
# 9c. The first, last, and all major words in titles are capitalized. (See 10a
#  and 16c.)
#
# In the style favored by the Modern Language Association (MLA) and in that
# recommended by the Chicago Manual of Style (CMS), all words in titles and
# subtitles are capitalized, except articles, coordinating conjunctions,
# prepositions, and the to in infinitives (unless they are the first or last
# word). The articles are a, an, and the; the coordinating conjuctions are and,
# but, for, nor, or, so, and yet. (A list of common prepositions can be found
# in chapter 1; see page 19.) MLA style favors lowercasing all prepositions,
# including long prepositions such as before, between, and through, which
# formerly were capitalized. APA style requires capitalizing any word that has
# four or more letters, including prepositions.
#
#         * The Scarlet Letter
#         * "How to Be a Leader"
#         * From Here to Eternity
#         * "What This World Is Coming To
#         * Mean Are from Mars, Women Are from Venus [MLA and CMS]
#         * Mean Are From Mars, Women Are From Venus [APA]
#
#
# In a title, MLA, APA, and CMS recommend capitalizing all words of a
# hyphenated compound except for articles, coordinating conjunctions, and
# prepositions unless the first element of the compound is a prefix.
#
#         * "The Building of the H-Bomb" [noun]
#         * "The Arab-Israeli Dilemma" [proper adjective]
#         * "Stop-and-Go Signals" [lowercase coordinating conjunction]
#
# Because all three style manuals recommend that, in general, compounds with
# prefixes not be hyphenated except in special circumstances, the resulting
# single-word combinations follow the normal rules of capitalization. However,
# if misreading could occur (as in un-ionized or re-cover), if the second
# element begins with a capital letter (pre-Christmas), or if the compound
# results in a doubled letter that could be hard to read (anti-intellectual),
# all style manuals recommend hyphenating the compound. MLA and APA capitalize
# both elements of these compounds with prefixes, whereas CMS capitalizes only
# those elements that are proper nouns or proper adjectives. (While MLA does
# not specifically mention compounds with self-, both APA and CMS usually
# hyphenate self- compounds.)
#
#         * "Colonial Anti-Independence Poetry" [MLA]
#         * "Anti-Independence Behavior in Pre-Teens" [APA]
#         * "Anti-independence Activities of Delaware's Tories" [CMS]
#
#
# However, in titles that appear in lists of references, APA style permits
# capitalizing only the first word and any proper nouns or proper adjectives.

#    -- Hodges, John C. Hodges' Harbrace Handbook. 14th ed. Fort Worth:
# Harcourt, 2001.

$:.unshift(File.join(File.dirname(__FILE__),'..','..','lib')) unless $:.include?(File.join(File.dirname(__FILE__),'..','..','lib'))
require "withindex.rb"

module TitleCase
  # mix into String

  ARTICLES = %w(a an the)
  COORDINATING_CONJUNCTIONS = %w(and but for nor or so yet)
  COMMON_PREPOSITIONS = %w(
    about beneath in regarding above beside inside round
    across between into since after beyond like through
    against by near to among concerning of toward
    around despite off under as down on unlike
    at during out until before except outside up
    behind for over upon below from past with
  )

  EXCEPTIONS = ARTICLES + COORDINATING_CONJUNCTIONS + COMMON_PREPOSITIONS

  def icap # intelligent capitalization
    a = downcase
    if a =~ /^['"\(\[']*(\w)/
      i = a.index($1)
      a[i, 1] = a[i, 1].upcase
    end
    a
  end

  def icap!
    replace(icap)
  end

  def titlecase(exceptions = [])
    exclude = EXCEPTIONS + exceptions
#Modification: The original split on word boundaries. We don't like spaces in filenames, so split on _
    b = downcase.split(/\b/)
    len = b.length
    b.map_with_index {|w, i|
      if w.roman_numeral? or (w.length == 1 && b[i+1] == '.')
        w.upcase
        # always capitalize first and last words
      elsif i == 0 or i == len
        w.icap
        # don't capitalize the second half of words with apostrophes
#Modification: Capitalize if the preceding work ends in a numeric value
      elsif (exclude.include?(w) or (i>1) && b[i-1] == "'" && b[i-2] =~ /\w/) && (i>1 && b[i-1] =~ /\D\B/)
        w
      else
        w.icap
      end
    }.join
  end

  # taken from OZAWA Sakuro's Roman.pm
  ROMAN = /^(?:M{0,3})(?:D?C{0,3}|C[DM])(?:L?X{0,3}|X[LC])(?:V?I{0,3}|I[VX])$/i
  def roman_numeral?
    self =~ ROMAN ? true : false
  end
end
