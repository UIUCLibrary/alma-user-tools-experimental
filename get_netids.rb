#!/usr/bin/env ruby

require 'rubygems'
require 'net/ldap'
require 'yaml'
require 'logging'

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



infile_path = ARGV[0] ? ARGV[0] : '_data/staff.csv' 

uins = File.readlines(infile_path).map(&:chomp).select { |line| line.match(/^\s*[^#]/) }

ad = _setup_ldap()

log = Logging.logger[self]

treebase = 'ou=People,dc=ad,dc=uillinois,dc=edu'

people = Array.new

uins.each do | uin |
  filter = Net::LDAP::Filter.eq('uiucEduUin',uin)
  attrs  = ['cn']

  netids = Array.new

  search_for_netids = ad.search( :base   => treebase,
                                 :filter => filter,
                                 :attributtes => attrs,
                                 :return_result => false,
                               ) do | entry |
    if entry.respond_to?('cn') then
      netids = netids + entry.cn.map(&:to_s)  
    end

    people.push( { uin: uin,
                   netids: netids } )   

  
  end

end

File.open("_data/staff_added_netids.yml", "w") { | file | file.write(people.to_yaml) }
