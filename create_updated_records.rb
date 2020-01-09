#!/usr/bin/env ruby
require 'yaml'
require 'nokogiri'



def user_role_exists?( xml, role )

  # this is awkward...

  user_roles = xml.xpath( '/user/user_roles/user_role' )
  
  user_roles.each do | user_role |

    if user_role.xpath( 'role_type[contains(text(),"' + role[:id].to_s + '")]' ).empty? and user_role.xpath( 'scope[contains(text(),"' + role[:scope] + '")]' ).empty? 
      return true
    end

  end

  

  false

end

# seems awkward, scopes probably should be part of a role object
# ...consider refactoring...

def add_role( xml, person, role )

  if user_role_exists?(xml, role)
    puts "Would add role to " + person[:netids][0] + ' (' + person[:uin] + ')' +  role.to_s
  else
    puts "Would not add role to " + person[:netids][0] + ' (' + person[:uin] + '), role already exists '
  end
  
  #  elsif xml.xpath( xpath ).empty?
#    puts person[:netids][0] + ' (' + person[:uin] + ')' +   " doesn't have role #{role_id} set,  adding with scopes of " + person[:scopes].join(",")#
#
#    
#  else
#    puts person[:uin] + " #{role_id} already set "
#  end 
end


# TODO: reafactor so xml part of a person class
# to make stuff flike add_Role le

people = YAML::load_file('_data/staff_added_scopes.yml')

source_xml_dir = '_current_xml' ;
updated_xml_dir = '_updated_xml' ;



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


  #TODO: Make some sort of object to represent roles, that way can generate necessary xml easier....
  unscoped_role_ids = [214,52,239,200]



  # 221 Circulation Desk Manager
  # 32  Circulation Desk Operator
  # 51  Requests Operator
  scoped_role_ids = [51,32,221]

  
  default_roles = unscoped_role_ids.map { | role_id | { :id => role_id, :scope => '01CARLI_UIU' }  }

  puts person 

  # we might want to default to scoped roles being for everything if there is no scoping?
  # probably should at least warn
  unless person[:scopes].nil? or person[:scopes].empty?
    person[:scopes].each do | scope_id |
      scoped_role_ids.each do | role_id |
        default_roles.push( { :id => role_id, :scope => scope_id }  )
      end
    end
  else
    puts "No scopes found for " + person[:netids][0]
  end
  

  puts default_roles
  
  default_roles.each do | role |
    add_role( xml, person, role )
  end

#  File.write(updated_xml_dir + '/' + person[:uin] + '.xml', updated_xml.to_xml ) 
  
end 

