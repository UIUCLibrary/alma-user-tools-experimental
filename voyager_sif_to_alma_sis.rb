require './lib/voyager/patron_file_parser.rb'
require 'nokogiri'
require 'pp'


def build_barcodes( xml, user, voyager_patron )

  # so...barcodes are user_identifiers, which means...we need the user_idetnfier node...

  # in voyager barcode can have the following stasues....
  #
  # 1 = Active, 2 - InActive.
  #
  # Looks like we were keeping some of the old barcodes, I want to say I've seen 5 before too...


  # not sure if we can have two active barcodes in Alma....

  barcodes = Array.new
  user_identifiers = xml.xpath('/user/user_indentifiers').first

  if user_identifiers.nil?
    user_identifiers = xml.create_element('user_identifiers')
    user.add_child( user_identifiers )
  end
  
  (1..3).each do | barcode_sequence |
    barcode_value = voyager_patron['patron barcode ' + barcode_sequence.to_s] 
    if barcode_value.nil? or barcode_value.empty?
      next
    end
    ident_node = xml.create_element('user_identifier')

    ident_node.add_child( xml.create_element( 'id_type', 'BARCODE' ) )
    ident_node.add_child( xml.create_element( 'value', barcode_value ) )

    barcode_status = voyager_patron['barcode status ' + barcode_sequence.to_s].to_i == 1 ? 'ACTIVE' : 'INACTIVE'
                                                                       
    ident_node.add_child( xml.create_element( 'status', barcode_status ) )

    user_identifiers.add_child( ident_node )
    
  end
end

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

  build_barcodes( xml, user, entry ) 
  

  # voyager format for dates is yyyy.mm.dd, alma is accofding to the xsd date spec (basically we can do yyyy-mm-dd...
  
  # feels like we could set up a map and transform w/ method_missing?
  
  unless entry['patron expiration date'].nil? or entry['patron expiration date'].empty? 
    user.add_child( xml.create_element( 'expiry_date', entry['patron expiration date'].gsub(/\./, '-') ) )
  end
  
  
  unless entry['patron purge date'].nil? or entry['patron purge date'].empty? 
    user.add_child( xml.create_element( 'purge_date', entry['patron purge date'].gsub(/\./, '-') ) )
  end


  root_node.add_child( user.to_xml )

end
   
xml.add_child( root_node ) 
puts xml.to_xml

