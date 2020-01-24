# This is based off of VoyagerPatronFile.pm from UIUC patron feed process

module Voyager

  class PatronFile

    def initialize()
      @gen_info_fields = _general_information_fields();
      
      @addr_fields = _address_fields();

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
    

