#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'nokogiri'
require 'logging'
require 'yaml'

require 'net/ldap'


# so we need to actually make these into gems at some point
require __dir__ + '/lib/Alma/Batch/Api.rb'
require __dir__ + '/lib/Alma/Batch/user.rb'
require __dir__ + '/lib/employee_eppn_list.rb'



@log = Logging.logger['eppn_batch']

@log.add_appenders(
  Logging.appenders.stdout,
  Logging.appenders.file('eppn_batch.log',
                         :layout => Logging.layouts.pattern( :pattern => '[%d] %l %c: %m\n' )
                        ) 
)

@log.level = :debug



#TODO: put elsewhere? want to always pass in api, as that controls the rate limiting
# and also can handle certain errors by waiting and re-requesting

def update_user( api, user )

  
  connection_config = YAML::load_file( 'alma.yml' )

  update_url = 'https://' + connection_config['url_base'] + '/almaws/v1/users/' + user.primary_id
  api_uri = URI( update_url )

  
  request = Net::HTTP::Put.new( api_uri ) 
    
  request.body         = user.to_xml
  request.content_type =  'application/xml' 
  
   
    response = api.call( api_uri, request )
    
    # this is too verbose for even debug, uncomment only when really needed...
    #@log.debug( user.to_xml )
   
    if response.code.to_i >= 400 and response.code.to_i < 600
      
      
      @log.info("Got an error response (#{response.code}) on api call for #{user.eppn} (#{user.primary_id})")
      @log.debug("Error updating #{user.eppn} (#{user.primary_id})" +  response.body )
    end
end



# cycle...
#
# 1) Query AD, get a list of library employees (memberOf relation, but not a memberOf Outsiders) netids and uins
# 2) Go over these and...
#      a) unless user exists in alma
#            - for now, just log the uin, netid and note they don't exist, could consider adding them
#      b) if user does exist, see if eppn is the same as AD (if not exist, consider different...)
#           - yes? move to next person
#           - no? do an update w/ new eppn
# 


# TODO: Pull logger configuration out...
connection_config = YAML::load_file( 'alma.yml' )



# probably would be a better idea to do this in chunks instead of
# getting all the ad info right away....

# doing for testing...less of a headache...
#filter = Net::LDAP::Filter.construct("(memberOf:1.2.840.113556.1.4.1941:=CN=Library IT - IMS Faculty and Staff,OU=IT - IMS,OU=Units,OU=Library,OU=Urbana,DC=ad,DC=uillinois,DC=edu)")
#filter = Net::LDAP::Filter.construct("(cn=colwell3)")

library_employee_list = EmployeeEppnList.new(  )

@log.debug( "Found #{library_employee_list.all().length} entries ")



api = Alma::Batch::Api.new

# might need to uniq for the results, or modify employee list to do that.. maybe key w/ uin?
library_employees = library_employee_list.all()

library_employees.each do | person |
  
  unless person.key?('netid') and person.key?('uin')
    next
  end

  @log.debug( person.to_s ) 


  # let's see if they exist in alma
  # at some point we'll need to see if can get with either netid or uin, but for now going to just try uin
  url = 'https://' + connection_config['url_base'] + '/almaws/v1/users/' + person['uin'] 
  api_uri = URI( url )
  
  request = Net::HTTP::Get.new( api_uri ) 
  
  response = api.call( api_uri, request )

  # could examine body to see if error exists, but all 4xx or 5xx indicate errors...
  
  @log.debug("Got #{response.code} for request")
  if response.code.to_i >= 400 and response.code.to_i < 600
    @log.debug( "Error getting Alma record for  #{person['netid']} (#{person['uin']})" + response.body )
    next
  end
  
  
  raw_xml = response.body
  user = Alma::Batch::User.new( raw_xml )


  if user.id_missing?('NETIDSCOPED') or !user.active_id_type?('NETIDSCOPED')
    user.add_id('NETIDSCOPED', person['netid'] + '@illinois.edu',"Scoped Netid (eppn)" ) 
  else
    @log.debug(person['netid'] + " scoped netid already set ")
  end
  

  # it's going to be fairly commmon for INST_ID to be the primary key,
  # so to avoid a lot of chatter in the @logs going to check for that ...

  #TODO: make it easier to test for inactive statuses as well
  if user.id_missing?('INST_ID') or !user.active_id_type?('INST_ID') 
    user.add_id('INST_ID', person['uin'] )
  else
    @log.debug(person['uin'] + " inst_id already set ")
  end
  

#  @log.debug(user.to_xml)
  
  if user.changed
    @log.debug(user.primary_id + " changed, updating")
    update_user(api, user)
  end
  
end

