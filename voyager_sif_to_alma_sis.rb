require './lib/voyager/patron_file_parser.rb'
require 'nokogiri'
require 'pp'
require 'csv'


def voyager_day_to_alma_day( day )
  day.gsub(/\./, '-')
end

# maybe merge soeme of this into Alma::Batch;;User?

# TODO...refactor this...
# or use missing_method...
# seems like nokogiri should have some of this already..
def create_node_if_does_not_exist( xml, parent_node, name )
  node = parent_node.xpath(name).first

  
  if node.nil?
    node = xml.create_element(name)
    parent_node.add_child( node )
   end

  node
end

# needs a lot more love....
def guess_country_code( text )
  @country_code_lookup[ normalize( text ) ]


  
end

def normalize( text )
  text.gsub(/\s/,'').gsub(/[[:punct:]]/, '').gsub(/\p{S}/,'').downcase 
end

 


#  might be able to refactor with build_
def translate_addresses( xml, user, voyager_patron )

  contact_info = user.xpath('contact_info').first
  
  if contact_info.nil?
    contact_info = xml.create_element('contact_info')
    user.add_child( contact_info )
  end


  addresses = create_node_if_does_not_exist( xml,contact_info,'addresses')
  emails    = create_node_if_does_not_exist( xml,contact_info,'emails')
  phones    = create_node_if_does_not_exist( xml,contact_info,'phones')
  

  if voyager_patron.key?(:addresses)
    voyager_patron[:addresses].each do | source_address |
      
      puts "examining address"

      address_note = "" 
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
      
      if source_address["address type"].to_i == 3
        email = xml.create_element('email')
        email.add_child( xml.create_element( 'email_address', source_address['address line 1'] ) )

        email_types = xml.create_element(  'email_types' )

        types = ['school','work']

        types.each do | type |
          email_types.add_child( xml.create_element( 'email_type', type) )
        end

        email.add_child( email_types )
        
        emails.add_child( email )

      else
      
        address = xml.create_element( 'address' )

        (1..5).each do | line_number |
          source_line = source_address["address line " + line_number.to_s]
          address.add_child(xml.create_element("line#{line_number.to_s}",source_line) )
        end

        address.add_child(xml.create_element('city', source_address['city']) )
        address.add_child(xml.create_element('state_province', source_address['state (province) code']) )
        address.add_child(xml.create_element('postal_code', source_address['zipcode/postal code']) )


         # So....currently country is a 20 character free text field in sif, but needs to be a code in Alma...
        # This needs more attention in the long run, but for now will do a low-level mapping based off of normalization of the description...
        # TODO: add test cases
        
        # TODO: Add in warning to logger
        unless source_address['country'].nil? or source_address['country'].empty?
          address_note += "Country in original source was " + source_address['country'] + "\n"

          guess = guess_country_code( source_address['country'] )

          if guess
            address.add_child(xml.create_element('country', guess ) )
          else

            unmapped_warning = " Could not guess country for #{source_address['country']} \n"
            address_note += unmapped_warning
            puts unmapped_warning
          end
        end


        address.add_child( xml.create_element('start_date', voyager_day_to_alma_day( source_address['address begin date'] ) ) )
        address.add_child( xml.create_element('end_date', voyager_day_to_alma_day( source_address['address end date'] ) ) )

        # sincew we don't know but need a value here...populating with the ones that Ex Libris did
        address_types = xml.create_element('address_types')

        ['home','work','school','alternative'].each do | type |
          address_types.add_child( xml.create_element( 'address_type', type ) )
        end

        address.add_child( address_types )
        
        
        addresses.add_child( address )

        # phone (primary)
        # phone (mobile)
        # phone (fax)
        # phone (other)

        # do we want to dedup phone numbers, or can alma handle it sanely?
        translate_phones( xml, phones, source_address )
          
        end

      end
    end
end

# TODO: should have object that represent an address created from Voyager SIF
#       that can answer this question

def translate_phones( xml, phones, address )

  #a little messy, should consider breaking out logic
  phone_types_map = [{
                            :voyager_name => 'phone (primary)',
                            :alma_types   => ['home','work'],
                          },
                          {
                            :voyager_name => 'phone (mobile)',
                            :alma_types   => ['mobile'],
                          },
                          {
                            :voyager_name => 'phone (fax)',
                            :alma_types   => ['officeFax'],
                          },
                          {
                            :voyager_name => 'phone (other)',
                            :alma_types   => ['home','work','mobile']
                          } ]
  
  phone_types_map.each do  | phone |
    if not(address[phone[:voyager_name]].nil? or address[phone[:voyager_name]].empty?)

      phone = xml.create_element('phone')
      phone.add_child( xml.create_element( 'phone_number', address[ phone[ :voyager_name ] ] ) )

      phone_types = xml.create_element('phone_types')
      phone[:alma_types].each do | type |
        phone_types.add_child( xml.create_element( 'phone_type', type ) )
      end

      phone.add_child( phone_types )

      phones.add_child( phone )
      
    end
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
  
  if patron_groups.length > 0
    
    user.add_child(xml.create_element('user_group', patron_groups.sort { |a,b| priorities[a] <=> priorities[b] }.first ) )

  end
  
end


@country_code_lookup = Hash.new
CSV.read('country_lookup.map').each {|text,code|  @country_code_lookup[text] = code }

parser = Voyager::PatronFileParser::new

# probalby should pull this up a level,
# we'll need this for dealing with patron groups
priorities = Hash.new
File.readlines( 'patron_group_priority.txt', chomp: true)


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
    user.add_child( xml.create_element( 'purge_date', voyager_day_to_alma_day( entry['patron purge date'] ) ) )
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

  if entry.key?(:addresses)
    translate_addresses( xml, user, entry ) 
  end
  
  #Ok, doing this for now just to validate xml w/ xsd
  File.write('_sis_xml/' + entry['institution id'] + '.xml', user.to_xml ) 
  
  root_node.add_child( user.to_xml )
end
   
xml.add_child( root_node ) 
puts xml.to_xml

