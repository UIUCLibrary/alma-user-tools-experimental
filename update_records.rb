#!/usr/bin/env ruby
require 'yaml'
require 'nokogiri'

def add_role( xml, person, role_id )

  xpath = '/user/user_roles/user_role/role_type[contains(text(),"' + role_id.to_s + '")]'

  if xml.xpath( xpath ).empty?
    puts person[:netids][0] + ' (' + person[:uin] + ')' +   " doesn't have role #{role_id} set, would add "
  else
    puts person[:uin] + " #{role_id} already set "
  end 
end

# TODO: reafactor so xml part of a person class
# to make stuff flike add_Role le

people = YAML::load_file('_data/staff_added_netids.yml')

source_xml_dir = '_current_xml' ;
updated_xml_dir = '_updated_xml' ;

people = YAML::load_file('_data/staff_added_netids.yml')



people.each do | person |

  xml = File.open(source_xml_dir + '/' + person[:uin] + '.xml') { |file| Nokogiri::XML( file ) }

  updated_xml = xml
  
  if xml.xpath('/user/user_identifiers/id_type[contains(text(),"NETIDSCOPED")]').empty?
    puts person[:uin] + " doesn't have scoped netid set, would add " + person[:netids][0] + '@ilinois.edu'

    eppn_identifier_node = updated_xml.create_element( 'user_identifier' )

    eppn_identifier_node.add_child( updated_xml.create_element 'id_type', 'SCOPEDNETID', :desc => "Scoped Netid (eppn)"  )
    eppn_identifier_node.add_child( updated_xml.create_element 'value', person[:netids][0] + '@isllinois.edu' )
    eppn_identifier_node.add_child( updated_xml.create_element 'note', 'Added by script on ' + Time.now.to_s )
    eppn_identifier_node.add_child( updated_xml.create_element 'status', 'ACTIVE' )

    # probably shoudl skip and warn if no identifier block
    xml.xpath('/user/user_identifiers').first.add_child( eppn_identifier_node )

  else
    puts person[:uin] + " scoped netid already set "
  end
  
  # Work Order Operator
  # 214
  #
  # Fulfillment Administrator - Read Only
  # 52
  #
  # Resource Sharing Partners Manager  
  # 239
  #
  # Requests Operator
  # 51
  #
  # Circulation Desk Operator
  # 32
  #
  # Circulation Desk Manager
  # 221
  #
  # Patron
  # 200
  # 


  roles = [214,52,239,51,32,221,200]

  roles.each do | role |

    add_role( xml, person, role )
  end

  File.write(updated_xml_dir + '/' + person[:uin] + '.xml', updated_xml.to_xml ) 
  
end 

