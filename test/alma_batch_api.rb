require 'test/unit'
require 'webmock/test_unit'
require __dir__ + '/../lib/Alma/Batch/Api.rb'
require 'uri'

class TestAlmaBatchAPI < Test::Unit::TestCase
  

  def test_control

    puts "control test started"
    
    # this is complete guess work,
    # but will test 30 times and if 29 get done in less
    # than a second, the reest of the tests are reasonable
    
    api = Alma::Batch::Api.new( __dir__ + '/test_alma.yml' )
    

    mock_responses = (1..30).map { | position | { body: "<user><primary_id>#{position.to_s }</primary_id></user>" } }
    
    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
    
    
    less_than_a_second_count = 0

    (1..30).each do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )

      uri = URI( 'https://foo/user/1' )
      request = Net::HTTP::Get.new( uri )
      api.call( uri, request  )
      
      if Process.clock_gettime(Process::CLOCK_MONOTONIC ) - start_time < 1 then
        less_than_a_second_count += 1
      end
    end
    
    assert_compare(less_than_a_second_count, '>', 29 ) 
    

    puts "control test ended"
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

    puts mock_responses
    
    # set up webmock
    stub_request(:any, /.*/).to_return( mock_responses )
    
    
    more_than_a_second_count = 0

    (1..30).each do | position |
      puts "At request #{position}" 
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )

      uri = URI(  'https://foo/user/1' )
      request = Net::HTTP::Get.new( uri )
      
      api.call( uri, request  )
      
      if position % 5 == 0 and (Process.clock_gettime(Process::CLOCK_MONOTONIC ) - start_time ) > 1 then
        puts "got time delay"
        more_than_a_second_count += 1
      end
    end
    
    assert_compare(more_than_a_second_count, '>=' , 6 ) 
    
    puts "per second message test ended"
  end
end
