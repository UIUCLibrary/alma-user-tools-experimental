#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'yaml'

connection_config = YAML.load( File.open( 'alma.yml' ) ) ;


# we probably should get the id
# from the xml file, but for now  trying to avoid being fancy

#user_file_path = ARGV[0] ;
#user_id        = ARGV[1] ;

Dir.foreach('_updated_xml') do |filename|
  next if filename !~ /\.xml$/
  user_id = filename.match(/^(.*)\.xml$/)[0]
  
  url = 'https://' + connection_config['url_base'] + '/almaws/v1/users/' + user_id
  
  puts "Will try update with " + url
  
  api_uri = URI( url )
  
  request = Net::HTTP::Put.new( api_uri ) 
  
  request.body         = File.read('_updated_xml/' + filename) 
  request.content_type =  'application/xml' 
  
  #header neeeds to be Authorization: apikey {APIKEY}
  request['Authorization'] = 'apikey ' + connection_config['api_key']
  
  response = Net::HTTP.start(api_uri.hostname, api_uri.port, :use_ssl => true) { | http |
    http.request( request )
  }
  puts response.body


  # Do work on the remaining files & directories
end



