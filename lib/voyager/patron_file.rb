# This is based off of VoyagerPatronFile.pm from UIUC patron feed process

module Voyager

  class PatronFile

    LENGTH_ADDRESS_ENTRY = 429
    INITIAL_ADDRESS_OFFSET = 456
      

    #TODO: if a numeric format....cast via to_i when assigning to array
    def initialize()
      @gen_info_fields = _general_information_fields();
      
      @addr_fields = _address_fields();

    end



    def parse_file( file_path ) 

      people = []

      puts file_path
      File.open(file_path, "r").each do | line |
        people.push( self.parse_person(line) )
      end

      people
    end

    def parse_person( line ) 

      line = line.chomp
      
      # first, we go through the general info
      # and print the corresponding part of the
      # line, we do assume that the info is valid

      #if the addressCount not digit, then guess 3 (home, work, email)
      address_count = 3
      
      person = {}
      
      @gen_info_fields.each do | gen_field |
        field_contents = line[gen_field[:offset].to_i - 1, gen_field[:length].to_i]
        person[gen_field[:name]] =  field_contents

        if gen_field[:name] == 'address count' and field_contents =~ /^\d$/
          address_count = field_contents
        end
      end

      #then we loop on address as many times as necessary
      #refactor?
      
      
      #the way the addresses are set in the manual are kind of stupid
      #the offset is only valid for the first address...really....
      #so need to subtract by that each time, 
      #but add the difference to get the "current position"
      
      addresses = []
      
      (0..(address_count.to_i-1)).each  do | address_number |
        address = {}
        @addr_fields.each do | addr_field |
          address[ addr_field[:name] ] = line[addr_field[:offset].to_i + (address_number * LENGTH_ADDRESS_ENTRY) - 1, addr_field[:length].to_i] 
        end
        
        addresses.push( address )
      end
      
      person[:addresses] = addresses
      
      current_offset = INITIAL_ADDRESS_OFFSET + (LENGTH_ADDRESS_ENTRY * address_count.to_i);
  
      #then space for any notes

      notes = line[current_offset,1000]
      
      unless notes.nil? or notes =~ /^\s*$/
        person[:notes] = notes;  
      end

      if line.length  > current_offset + 1000
        person[:excess] = line[(current_offset + 1000 - 1),line.length]
      end

      person
    end
    

    
    
    private


    def _general_information_fields
      if @gen_info_fields
        return @gen_info_fields
      end
      
      _format_map( __dir__ + "/manual_info/patron_general.fmt" )
    end
    
    def _format_map( format_file_path ) 
      fields = []
      
      # this is some text files that extracted 
      # by dumping the Voyager Administrator manaul
      # through pdftotext, then doing some hand-massaging
      # with excel
      
      format_file = File.open( format_file_path, 'r')
      
      headers  = format_file.readline.chomp
      
      format_file.each do | line |
        line = line.chomp
        line_fields = line.split("\t")
        
        fields.push({
		      :order    => line_fields[0],
		      :name     => line_fields[1],
		      :offset   => line_fields[2],
		      :format   => line_fields[3],
		      :required => line_fields[4],
		      :length   => line_fields[5], 
		    })
	
      end
      
      fields
    end

    ####################### end of gen info formatting

    
    ######################
    #
    # Setup address information format
    #
    #######################
    def _address_fields 
      if(@addr_fields) 
        return @addr_fields
      end
      
      _format_map( __dir__ + "/manual_info/p_addr.fmt" )
    end


    
  end
end
    

