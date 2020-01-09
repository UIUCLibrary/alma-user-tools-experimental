#!/usr/bin/env ruby

require 'yaml'
require 'logging'
require 'oci8'

def _setup_voyager_connection()
  config = YAML::load_file('voyager.yml')

  OCI8.new( config['sid'] )
end

#TODO: refactor?
def circ_profile_name_to_alma_scope(circ_profile_name)
  circ_profile_name.upcase.gsub(/[[:space:]]/,'')
end



voyager = _setup_voyager_connection()


query = "select circ_profile_name from circ_operator inner join circ_profile on circ_operator.circ_profile_id = circ_profile.circ_profile_id where operator_id = :id"

cursor = voyager.parse( query )

  
people = YAML::load_file('_data/staff_added_netids.yml')

puts people

scope_mapping_exceptions = YAML::load_file('circ_profile_name_to_alma_library.map') 


puts scope_mapping_exceptions

people.each do | person |
  
  scopes = Array.new
  
  person[:netids].each do | netid |
    
    cursor.bind_param(:id, netid)
    cursor.exec
    
    cursor.fetch do | row |
      circ_profile_name = row[0]

      # looking like will need to refactor
      # since some patterns are adding info after Level
      if matches = circ_profile_name.match( /^[[:space:]]*(?<cpn_front>.*)[[:space:]]Level/ )
        
        
        circ_profile_name_part = matches[:cpn_front]
        
        
        if scope_mapping_exceptions.has_key?(circ_profile_name_part.downcase)
          scopes = scopes + scope_mapping_exceptions[circ_profile_name_part.downcase]["codes"].map(&:to_s)
        else
          scopes.push( circ_profile_name_to_alma_scope( circ_profile_name_part ) )
        end
      end
    end
    puts person[:uin] + "," + scopes.join(";")
    person[:scopes] = scopes
  end
end

File.write("_data/staff_added_scopes.yml", people.to_yaml)

                           
  

  
