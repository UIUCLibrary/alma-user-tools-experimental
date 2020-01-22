module Alma
  module Batch

    require 'limiter'
    require 'nokogiri'
    require 'yaml'
    
    # adding a gem just to track time and limit calls might
    # be overkill, can probably implement ourselves directly...
    
    class Api
      extend Limiter::Mixin
      
      limit_method :call, rate: 19, interval: 1
      

      def initialize(config_file = 'alma.yml')
        # probably should do something more rails like ...but for now... 
        @config = YAML::load_file( config_file )
      end
      
      def sleep_till_midnight
        
        current_time  = Time.now.gmtime
        tomorrow_time = current_time + (24 * 60 * 60)
        tomorrow_time.gmtime
        
        gm_first_second_of_tmorrow = Time.gm(tomorrow_time.year,
                                             tomorrow_time.month,
                                             tomorrow_time.day,
                                             0,
                                             0,
                                             1)

        seconds_till_after_midnight = gm_first_second_of_tmorrow - current_time

        # for quick debugging purposes, should remove or
        # set up logger

        puts "Will sleep for #{seconds_till_after_midnight}"
       
        sleep( seconds_till_after_midnight )
        
      end
      
      # we might want to break out some of the longer stuff into
      # unlimited, doesn't make sense to wait before doing
      # actual request part

      
      def call(url, request,  xml = '', *args)
        # Alma throttles for both overall
        # requests per day as well as per second
        #
        # These are PER INSTITUTION, not per conncoection / api key
        # so even if our throttling is working we might get warnings
        # about exceeding either threshold.
        #
        # If it's the daily , we'll want to do a warning
        # and sleep for the rest of the day...
        #
        # if it's the per_second threshold, we should
        # just wait a second (and issue a warning)

        
        throttled_result = true
        response = nil
        while throttled_result do
          
          #header neeeds to be Authorization: apikey {APIKEY}
          request['Authorization'] = 'apikey ' + @config['api_key']
          
          response = Net::HTTP.start(url.hostname,
                                     url.port,
                                     :use_ssl => true) { | http |
            http.request( request )
          }
          
          raw_xml = response.body
                    
          xml = Nokogiri::XML( raw_xml ) 

          # see daily_threshold.xml for an example of what is returend
          # when we hit the daily threshold (not clear what http code
          # this is relative to midnight GMT
          # see concurrent_threshold.xml (also called per_second_threshold in docs) for example of taht
          # this will be returned w/ a code of 429


          # will need to investigate to see if namespace is actually returned in errors unlike some of the other stuff...
          
          #          daily_threshold_xpath = '
          daily_threshold_xpath = '//ae:web_service_result'


          # since results are normally not namespaced, we may be better off just doing xml.remove_namespaces!
          # rather than trusting the docs that these are actually namespaced
          
          # check for daily limit, sleep til midnight GMT if found
          if !xml.xpath( '/ae:web_service_result/ae:errorList/ae:error/ae:errorCode[contains(text(),"DAILY_THRESHOLD")]',
                         { 'ae' => "http://com/exlibris/urm/general/xmlbeans"} ).empty?
            puts "Warning - reached daily limit for API, going to sleep"
            sleep_till_midnight()
            
          # check for second limit, sleep till next second if found. Don't need to check body, docs say this always returns 429 if it is triggered
          elsif response.code == '429'
            puts "Warning - reached per-second threshold, going to sleep and try again"
            sleep(1)
            
          else
            throttled_result = false
          end
        end
        
        # for now returning response, api only cares about throttle, not errors, etc atm
        #       puts "Ok, got a response that wasn't throttled, going to return that"
        response
      end
    end
  end
end
