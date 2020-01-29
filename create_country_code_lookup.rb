#!/usr/bin/env ruby

# this is a quick and dirty solution to try to at least get some country codes done
# we're just normalizing by removing punctuation, spaces, and downcasing everything...

# todo: refactor normalize_text out...

def normalize( text )
  text.gsub(/\s/,'').gsub(/[[:punct:]]/, '').gsub(/\p{S}/,'').downcase
end


mapping = File.open('country_lookup.map','w')

File.open('alma_country_codes.tsv','r').readlines.each do | line |

  line = line.chomp

  (code, text) = line.split("\t")

  mapping.puts( normalize( text ) + ',' + code )
  
  
end


