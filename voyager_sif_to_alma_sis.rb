require './lib/voyager/patron_file_parser.rb'
require 'nokogiri'
require 'pp'

# maybe merge soeme of this into Alma::Batch;;User?



def get_user_child_node( xml, user, name )
  node = xml.xpath("/users/#{name}").first
  
  if node.nil?
    node = xml.create_element('name')
    user.add_child( node )
  end

  node
end


#  might be able to refactor with build_
def translate_addresses( xml, user, voyager_patron )
 
  addresses = get_user_child_node( xml, user, 'addresses' )
  
  phones = get_user_child_node( xml, user, 'phones' )

  emails = get_user_child_node( xml, user, 'emails')   
  voyager_patron['addresses'].each do | address |
    
    # address id
    # address type     1 = permanent -- only one is permitted 2 = temporary 3 = e-mail
    # address status code n = normal h = hold mail
    # address begin date
    # address end date
    # address line 1
    # address line 2
    # address line 3
    # address line 4
    # address line 5
    # city
    # state (province) code
    # zipcode/postal code
    # country
    # date added/updated

    # Alma
    # line1	string	Line 1 of the address. Mandatory.
    # line2	string255Length	Line 2 of the address.
    # line3	string255Length	Line 3 of the address.
    # line4	string255Length	Line 4 of the address.
    # line5	string255Length	Line 5 of the address.
    # city	string255Length	The address' relevant city. Mandatory.
    # state_province	string255Length	The address' relevant state.
    # postal_code	string255Length	The address' relevant postal code.
    # country	with attr.	The address' relevant country. (CODE)
    # address_note	string1000Length	The address' related note.
    # start_date	date	The date from which the address is deemed to be active.
    # end_date	date	The date after which the address is no longer active.
    # address_types	address_types	Address types. Mandatory.
 


    
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


    # phone (primary)
    # phone (mobile)
    # phone (fax)
    # phone (other)


  end

end

def translate_barcodes( xml, user, voyager_patron )

  # so...barcodes are user_identifiers, which means...we need the user_idetnfier node...

  # in voyager barcode can have the following stasues....
  #
  # 1 = Active, 2 - InActive.
  #
  # Looks like we were keeping some of the old barcodes, I want to say I've seen 5 before too...

  
  # not sure if we can have two active barcodes in Alma....

  user_identifiers = xml.xpath('/user/user_indentifiers').first

  if user_identifiers.nil?
    user_identifiers = xml.create_element('user_identifiers')
    user.add_child( user_identifiers )
  end

  patron_groups = Array.new
  
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

    # active barcode, we want to add patron group to array
    if voyager_patron['barcode status ' + barcode_sequence.to_s].to_i == 1
      patron_groups.push( voyager_patron['patron group ' + barcode_sequence.to_s] )  
    end
  end

  puts "pulled out following patron groups\n"
  puts pp patron_groups
  # we'll need this for dealing with patron groups
  prorities = Hash.new
  File.readlines( 'patron_group_priority.txt', chomp: true)
  
  if patron_groups.length > 0
    
    user.add_child(xml.create_element('user_group', patron_groups.sort { |a,b| priorities[a] <=> priorities[b] }.first ) )

  end
  
end

parser = Voyager::PatronFileParser::new

patron_group_priority = 


entries = parser.parse_file( ARGV[0] ) 


# might be memory intensive, might want to
# create individual files and then just concat them and add root element

xml = Nokogiri::XML::Document.new()

root_node = xml.create_element("users")

entries.each do | entry |

  pp entry
  
  user = xml.create_element("user")
  user.add_child("<primary_id>#{entry['institution id']}</primary_id>")

  translate_barcodes( xml, user, entry ) 
  

  # voyager format for dates is yyyy.mm.dd, alma is accofding to the xsd date spec (basically we can do yyyy-mm-dd...
  
  # feels like we could set up a map and transform w/ method_missing?
  # maybe default to it being on the top level? seems like we could abstract this better...
  
  unless entry['patron expiration date'].nil? or entry['patron expiration date'].empty? 
    user.add_child( xml.create_element( 'expiry_date', entry['patron expiration date'].gsub(/\./, '-') ) )
  end
  
  
  unless entry['patron purge date'].nil? or entry['patron purge date'].empty? 
    user.add_child( xml.create_element( 'purge_date', entry['patron purge date'].gsub(/\./, '-') ) )
  end


  # in voyager, name_type 1=personal name, 2=institutional name
  # but assuming for this that we're always using personal name...

  unless entry['first name'].nil? or entry['first name'].empty? 
    user.add_child( xml.create_element( 'first_name', entry['first name'] ) )                    
  end

  unless entry['middle name'].nil? or entry['middle name'].empty? 
    user.add_child( xml.create_element( 'middle_name', entry['middle name'] ) )                    
  end

  unless entry['surname'].nil? or entry['surname'].empty? 
    user.add_child( xml.create_element( 'last_name', entry['surname'] ) )                    
  end


  # historical charges - not finding in Alma, might be in a different api
  # claims returned count - not finding in Alma, might be in a different api
  # self-shelved count - not finding in alma, moight be in a different api
  # lost items count
  # late media returns
  # historical bookings
  # canceled bookings
  # unclaimed bookings
  # historical callslips
  # historical distributions
  # historical short loans
  # unclaimed short loans
  

  # maybe merge into notes? other stuff in notes
  # statistical category 1
  # statistical category 2
  # statistical category 3
  # statistical category 4
  # statistical category 5
  # statistical category 6
  # statistical category 7
  # statistical category 8
  # statistical category 9
  # statistical category 10

  if entry.key?('addresses')
    translate_addresses( xml, user, entry ) 
  end
  
  #Ok, doing this for now just to validate xml w/ xsd
  File.write('_sis_xml/' + entry['institution id'] + '.xml', user.to_xml ) 
  
  root_node.add_child( user.to_xml )
end
   
xml.add_child( root_node ) 
puts xml.to_xml

