class EmployeeEppnList

  require 'net/ldap'
  require 'yaml'
  require 'logging'


  # we may want to consider filtering out 
  # those who are in Library Outsiders w/ something like...
  #
  # (&(filter_below)(!(memberOf:1.2.840.113556.1.4.1941:=CN=Library Outsiders,OU=Library,OU=Urbana,DC=ad,DC=uillinois,DC=edu)))
  
  
  def initialize( filter = nil )
    # feels wrong, but need to look at more examples of using 'logging'
    @log = Logging.logger[self]
    
    @log.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('eppn_batch.log')
      
    )
    
    @log.level = :debug

    @log.debug("Getting employees") 
    @employees = _get_employees( filter )

    @log.debug("Found " + @employees.length.to_s + " that matched AD filter")
  end
  
  # TODO: move more of this to config file, make more generic and usable elsewhere without
  # having to change code


  def all
    @employees
  end

  
  private 
  
  def _setup_ldap()
    config = YAML::load_file('ldap.yml')
    
    Net::LDAP.new :host => config['host'],
                  :port => 389,
                  :auth => {
                    :method   => :simple,
                    :username => config['user'],
                    :password => config['password'],
                  },
                  :encryption => {
                    :method => :start_tls,
                    :tls_options => OpenSSL::SSL::SSLContext::DEFAULT_PARAMS,
                  }
    
  end
  
  
  def _get_employees( filter = nil)

    @log.debug("_get_employees called")
    
    ad = _setup_ldap()
    
    treebase = 'OU=People,DC=ad,DC=uillinois,DC=edu'
    attrs    = ['cn','uiuceduuin']
    
    people = Array.new

    # we should see if we can pull this out into a configuration
    # think there's a way to use the extension operations...
    filter ||= Net::LDAP::Filter.construct("(memberOf:1.2.840.113556.1.4.1941:=CN=Library - all users,OU=Library,OU=Urbana,DC=ad,DC=uillinois,DC=edu)")

    @log.debug( filter.to_s )
    
    search_for_netids = ad.search( :base   => treebase,
                                   :filter => filter,
                                   :attributtes => attrs,
                                   :return_result => false,
                                 ) do | entry |
      
      person = {}
      
      if entry.respond_to?('cn') and entry['cn'].length > 1 then
        @log.warn("multiple cn entries for user " + entry['cn'].join(', ') + ', will use first one')
      end
      
      if entry.respond_to?('cn') then
        person['netid'] = entry['cn'][0]
          
      end

      if entry.respond_to?('uiuceduuin') and entry['uiuceduuin'].length > 1 then
        @log.warn("multiple uiucEduUin entries for user " + entry['uiuceduuin'].join(', ') + ', will use first one')
      end

      if entry.respond_to?('uiuceduuin') then
        person['uin'] = entry['uiuceduuin'][0]
        
      end

      people.push( person )   
    end
    
    people
  end
end

      
      
      
