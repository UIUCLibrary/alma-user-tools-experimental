require './lib/voyager/patron_file_parser.rb'
require 'nokogiri'
require 'pp'

parser = Voyager::PatronFileParser::new


entries = parser.parse_file( ARGV[0] ) 


# might be memory intensive, might want to
# create individual files and then just concat them and add root element

xml = Nokogiri::XML::Document.new()

root_node = xml.create_element("users")

entries.each do | entry |

  pp entry
  
  user = xml.create_element("user")
  user.add_child("<primary_id>#{entry['institution id']}</primary_id>")
  

  root_node.add_child( user.to_xml )
end

xml.add_child( root_node ) 
puts xml.to_xml
