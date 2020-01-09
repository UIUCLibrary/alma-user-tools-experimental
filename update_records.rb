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

xml_dir = '_current_xml' ;

people = YAML::load_file('_data/staff_added_netids.yml')



people.each do | person |

  xml = File.open(xml_dir + '/' + person[:uin] + '.xml') { |file| Nokogiri::XML( file ) }

  if xml.xpath('/user/user_identifiers/id_type[contains(text(),"NETIDSCOPED")]').empty?
    puts person[:uin] + " doesn't have scoped netid set, would add " + person[:netids][0] + '@ilinois.edu'
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
  
  
end 

