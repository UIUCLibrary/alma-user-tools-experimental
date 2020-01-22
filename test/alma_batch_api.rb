require 'test/unit'
require 'webmock/test_unit'
require __dir__ + '/../lib/Alma/Batch/Api.rb'

class TestAlmaBatchAPI < Test::Unit::TestCase
  

  def test_control
    
    # this is complete guess work,
    # but will test 30 times and if 29 get done in less
    # than a second, the reest of the tests are reasonable
    
    api = Alma::Batch::Api.new
    
    
    # set up webmock 
    (1..30).each do
      stub_request(:any, /.*/)
    end
    
    less_than_a_second_count = 0

    (1..30).each do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC )
      
      if Process.clock_gettime(Process::CLOCK_MONOTONIC ) - start_time < 1 then
        less_than_a_second_count += 1
      end
    end
    
    assert_compare(less_than_a_second_count, '>', 29 ) 
    
    
  end
end
  #  it 'pauses for one second if hits PER SECOND threshold' do
#
#    api = Alma::Batch::Api.new

    # ok, this probably isn't the best way to test
    # as the tests themselves might take more than a second
    # doing lots of samples

    # Process.clock_gettime(Process::CLOCK_MONOTONIC )
    # we don't care about system clock, but we do care about
    # seconds it takes to do these tests...

    
#  end

  #it 'pauses for one second if gets 21 seconds in less than a second' do
  #  end


