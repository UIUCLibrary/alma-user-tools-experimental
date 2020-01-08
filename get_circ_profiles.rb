#!/usr/bin/env ruby

require 'yaml'
require 'logging'
require 'oci8'

def _setup_voyager_connection()
  config = YAML::load_file('voyager.yml')

  OCI8.new( config['sid'] )
end

voyager = _setup_voyager_connection()


query = "select circ_profile_name from circ_operator inner join circ_profile on circ_operator.circ_profile_id = circ_profile.circ_profile_id where operator_id = :id"

cursor = voyager.parse( query )

  
people = YAML::load_file('_data/staff_added_netids.yml')

puts people

people.each do | person |
  person[:netids].each do | netid |

    cursor.bind_param(:id, netid)
    cursor.exec

    cursor.fetch do |row|
      printf "%20s %20s\n",netid,row[0]
    end
  end
end



                           
  

  
