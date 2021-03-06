require 'test/unit'
require 'webmock/test_unit'
require __dir__ + '/../lib/Alma/Batch/Api.rb'
require 'uri'
require 'timeout'
class TestAlmaBatchAPI < Test::Unit::TestCase


  # TODO: refactor out common code in to a test method so
  # we just setup webmock and the expected timing results (maybe return times as array of int)

  def test_control

#    puts "control test started"
    
    # this is complete guess work,
    # but will test 30 times and if 29 get done in less
    # than a second, the rest of the tests are reasonable
    
    api = Alma::Batch::Api.new( __dir__ + '/test_alma.yml' )
    

    mock_responses = (1..30).map { | position | { body: "<user><primary_id>#{position.to_s }</primary_id></user>" } }
    
    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
    
    
    less_than_a_second_count = 0

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )
    (1..30).each do

      uri = URI( 'https://foo/user/1' )
      request = Net::HTTP::Get.new( uri )

      # we DON'T want to call the api for this test...
      
      
      response = Net::HTTP.start(uri.hostname,
                                 uri.port,
                                 :use_ssl => true) { | http |
        http.request( request )
      }
    end

    assert_compare(Process.clock_gettime(Process::CLOCK_MONOTONIC ) - start_time, '<', 1 ) 
    
#    puts "control test ended"
  end
  
  def test_pauses_after_per_second_warning
    
    api = Alma::Batch::Api.new

    # if we time out every five, we'll need to make sure we have 31, because WebMock repeats the last request
    # feels like better way to do this...
    mock_responses = (1..31).flat_map { | position |
      mock_response = []
      if position % 5 == 0 then
        mock_response.push( {status: 429,
                             body: File.read(__dir__ + '/concurrent_threshold.xml'), } )
      end
      mock_response.push( {status: 200,
                           body: "<user><primary_id>#{position.to_s}</primary_id></user>" } )
       mock_response  
    }  

    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
    
    
    more_than_a_second_count = 0

    (1..30).each do | position |
#      puts "At request #{position}" 
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )

      uri = URI(  'https://foo/user/1' )
      request = Net::HTTP::Get.new( uri )
      
      api.call( uri, request  )
      
      if position % 5 == 0 and (Process.clock_gettime(Process::CLOCK_MONOTONIC ) - start_time ) > 1 then
#        puts "got time delay"
        more_than_a_second_count += 1
      end
    end
    
    assert_compare(more_than_a_second_count, '>=' , 6 ) 
    
#    puts "per second message test ended"
  end



  # we're testing the built-in threshold of 20 seconds per minute here...
  # we should avoid hitting the threshold if we can without warnings from Alma..
  def test_pauses_after_too_many_request_per_second

    api = Alma::Batch::Api.new

    # if we time out every five, we'll need to make sure we have 31, because WebMock repeats the last request
    # feels like better way to do this...
    mock_responses = (1..30).map { | position |
      {status: 200,
       body: "<user><primary_id>#{position.to_s}</primary_id></user>" } 
    }  
    
    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
    
    
    
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )
    
    (1..30).each do | position |
#      puts "At request #{position} at " + Time.now.to_s 
      
      
      uri = URI(  'https://foo/user/1' )
      request = Net::HTTP::Get.new( uri )
      
      api.call( uri, request  )
      
    end

    time_elapsed = Process.clock_gettime( Process::CLOCK_MONOTONIC )  - start_time
    assert_compare(time_elapsed, '>=' , 1 )
    
    
#    puts "too many per second  test ended"
  end


  # this test isn't great, need to look at output
  # to see if the seconds it's going to wait are reasonable
  #
  
  def test_pauses_after_receiving_daily_threshold

    api = Alma::Batch::Api.new

    # if we time out every five, we'll need to make sure we have 31, because WebMock repeats the last request
    # feels like better way to do this...
    mock_responses = (1..10).map { | position |
      {status: 200,
       body: "<user><primary_id>#{position.to_s}</primary_id></user>" } 
    }  

    mock_responses.push( { status: 400, body: File.read(__dir__ + '/daily_threshold.xml') } )
    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
                         
                         
    #TODO: warn if happens in final minute of day according to UTC
    

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )

    uri = URI(  'https://foo/user/1' )
    (1..10).each do | position |
      #      puts "At request #{position} at " + Time.now.to_s 
      request = Net::HTTP::Get.new( uri )
      api.call( uri, request  )
    end

    # and 11th request should time out after 60 seconds...unless you're running this at 5:59pm Central or so
    request = Net::HTTP::Get.new( uri )
     
    assert_raise( Timeout::Error ) {
      Timeout::timeout( 60 ) do
        api.call( uri, request  )
      end
    }
    
  end


  
  
end
