#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'yaml'
require 'nokogiri'



def prettify( xml )
  doc = Nokogiri.XML( xml ) do |config|
    config.default_xml.noblanks
  end
  doc.to_xml(:indent => 2 ) 
end

def download_xml( user_id )

  connection_config = YAML.load( File.open( 'alma.yml' ) ) ;
  
  url = 'https://' + connection_config['url_base'] + '/almaws/v1/users/' + user_id ;
  puts "Will try get with " + url
  
  api_uri = URI( url )
  
  request = Net::HTTP::Get.new( api_uri ) 
  
  #header neeeds to be Authorization: apikey {APIKEY}
  request['Authorization'] = 'apikey ' + connection_config['api_key']

  response = Net::HTTP.start(api_uri.hostname, api_uri.port, :use_ssl => true) { | http |
    http.request( request )
  }
  
  xml = response.body
  
  user_file = File.new('_current_xml/' + user_id + '.xml', 'w') ;
  
  user_file.write( prettify( xml ) ) ;
  
  user_file.close
end

  
people = YAML::load_file('_data/staff_added_netids.yml')

people.each do | person |
  download_xml( person[:uin] )
end
