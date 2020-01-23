module Alma
  module Batch

    require 'nokogiri'

    
    # this is a wrapper around a Alma User xml doc
    class User

      ACTIVE_STATUS = 'ACTIVE'
      INACTIVE_STATUS = 'INACTIVE'


      attr_accessor :changed
      
      def initialize( xml_content )
        @xml = Nokogiri::XML( xml_content )

        @log = Logging.logger[self]
        
        @log.add_appenders(
          Logging.appenders.stdout,
          Logging.appenders.file('eppn_batch.log')
          
        )
        
        @log.level = :debug

        # simple approach..but requires
        # people modifying to change this value...
        # maybe Nokogiri XML could deal with ?
        #
        # better long run would be to have a semantic diff and see if
        # if meaningful changes have happened....
        @changed = false


        # comment out for most testing, would be one level below debug...

        @log.debug( @xml.to_xml(:indent => 2) )
        
      end


      
      def disable_ids_of( type )
      
      self.active_ids( type ).each do | id_node |
        id_node.xpath('status').each do | status_node |
          status_node.content = Alma::Batch::User::INACTIVE_STATUS
        end
      end
    end


      
      #TODO: maybe create user id class
      
      # maybe should have version that will NOT update?
      # or mode where it issues warnings? (ie id existed w/ different description or value, or was inactive
      def add_id(type, value, description = nil, status = Alma::Batch::User::ACTIVE_STATUS )
        
        #TODO: check value exists elsewhere as either primary key or another existing active id value
        #      and add, but overriding status to be inactive

        #TODO: clean up logic to make more readable

        if status == Alma::Batch::User::ACTIVE_STATUS and (self.primary_id == value or self.active_ids_by_value( value ).length > 0)
          
          # check to see if would be adding an identical inactive
          # id, not sure if that's a problem though, should test
          # TODO: test what happens with multlipe inactive ids and Alma api
          
          @log.warn("Id #{type} with #{value} either conflicts with primary_id #{self.primary_id} or another active id value")

          # So...at least when adding ids, even if inactive, they can't match the primary id
          # if self.find_ids({:id_type => type, :value => value, :status => Alma::Batch::User::INACTIVE_STATUS}).empty?
          # 
          #   @log.warn("changing #{type} to INACTIVE")
          #   status = Alma::Batch::User::INACTIVE_STATUS
          # end
          return 
        end
        
      #if  status == Alma::Batch::User::INACTIVE_STATUS and   self.find_ids({:id_type => type, :value => value, :status => Alma::Batch::User::INACTIVE_STATUS}).length > 0
      #    @log.warn("Already exists as an Inactive id, won't add")                        
      #    return
      #  end

        
        # TODO: figure out possilbe timing issues...
        # Ie we want to NOT do this if later on
        # something causes us to not add the identifier
        # also, this still MAY NOT WORK...might have to remove old inactive nodes
        if status == Alma::Batch::User::ACTIVE_STATUS
          @log.debug("disabling active ids that match the current type")
          self.disable_ids_of(type) 
        end


        
        identifier_node = @xml.create_element( 'user_identifier' )
        
        id_type_node = @xml.create_element 'id_type', type
 
        unless description.nil? or description.empty?
          id_type_node['desc']  = description  
        end
        
        identifier_node.add_child( id_type_node ) 
        identifier_node.add_child( @xml.create_element 'value', value )
        identifier_node.add_child( @xml.create_element 'note', 'Added by script on ' + Time.now.to_s )
        identifier_node.add_child( @xml.create_element 'status', status )

        # probably shoudl skip and warn if no identifier block
        @xml.xpath('/user/user_identifiers').first.add_child( identifier_node )


        @changed = true
      end

      
      def id_missing?( id_type )
        @xml.xpath('/user/user_identifiers/user_identifier/id_type[contains(text(),"' + id_type + '")]').empty?
      end

      def active_ids_by_value( value )
        find_ids({:value => value, :status => Alma::Batch::User::ACTIVE_STATUS})
      end
      
      def active_ids( id_type )
        find_ids({:id_type => id_type, :status => Alma::Batch::User::ACTIVE_STATUS})
      end

      def find_ids(options ) 

        conditions = Array.new        

        search_elements = [:id_type,:value,:status]

        search_elements.each do | search |
          
          unless !options.key?(search) or options[search].empty?
            conditions.push( %Q|#{search}[contains(text(),"#{options[search]}")]| )
          end
        end
        
        restriction_s = ''
        
        unless conditions.empty?
          restrictions_s = '[' + conditions.join(' and ') + ']'
        end
        
        xpath  = "/user/user_identifiers/user_identifier#{restrictions_s}"

        @log.debug( "searching nodes on #{xpath}" )
        @xml.xpath( xpath ) 
      end

      
      # should I throw error if done for something that doesn't exst, or just return true for that...
      def active_id_type?( id_type )

        #TODO: test to see if can upload an XML doc with both active and inactive
        self.active_ids( id_type ).length > 0 
       end

      # probably could have some sort of meta-programming w/ maps of where
      # certain attributes found...
      def primary_id
        @log.debug("Primary id called....value will be..." + @xml.xpath('/user/primary_id').first.content)
        
        # probabhly should throw out error if multiple primary ids....
        @xml.xpath('/user/primary_id').first.content
      end

      def to_xml
        @xml.to_xml
      end
      
    end
  end
end

