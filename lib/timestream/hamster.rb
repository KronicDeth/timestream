require 'rubygems'

require 'date'
require 'dbus'
require 'terminal-table/import'
require 'time'

module Timestream
  class Hamster
    class Fact
      attr_reader :category_name
      attr_reader :date
      attr_reader :delta_in_seconds
      
      def initialize(id, start_timestamp, end_timestamp, description, activity_name, activity_id, category_name, tag_list, date_timestamp, delta_in_seconds)
        @id = id
        
        # Convert start and end to Times
        @start_time = Time.at(start_timestamp)
        @end_time = Time.at(end_timestamp)
        
        @description = description
        @activity_name = activity_name
        @activity_id = activity_id
        @category_name = category_name
        @tag_list = tag_list
        
        # Convert date to a Date
        date_time = Time.at(date_timestamp)
        date = Date.new(date_time.year, date_time.month, date_time.day)
        @date = date
        
        @delta_in_seconds = delta_in_seconds
      end
    end
    
    def facts
      dbus_facts = proxy.GetFacts(@start_time.to_i, @end_time.to_i, '')
      # XXX for some reason GetFacts returns facts in a one-element array
      dbus_facts = dbus_facts[0]
      
      # convert dbus facts into instances
      dbus_facts.collect { |dbus_fact|
        Fact.new(*dbus_fact)
      }
    end
    
    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
    end
    
    def proxy
      @proxy ||= begin
        session_bus = DBus::SessionBus.instance
        hamster_service = session_bus.service('org.gnome.Hamster')
        hamster = hamster_service.object('/org/gnome/Hamster')
        # interfaces and therefore methods won't work if not first introspected
        hamster.introspect
        # set interface so methods can be called directly on object
        hamster.default_iface = 'org.gnome.Hamster'
        
        hamster
      end
    end
    
    class Timestream
      def [](date)
        @hours_by_date[date]
      end
      
      def []=(date, hours)
        @hours_by_date[date] = hours
      end
      
      def initialize
        @hours_by_date = Hash.new(0)
      end
      
      def each(&block)
        @hours_by_date.sort.each(&block)
      end
    end
    
    def timestream_by_category
      if @timestream_by_category.nil?
        @timestream_by_category = Hash.new { |hash, category|
          hash[category] = Timestream.new
        }
        
        facts.each do |fact|
          timestream = @timestream_by_category[fact.category_name]
          # convert seconds to fractional hours
          timestream[fact.date] += fact.delta_in_seconds.fdiv(60 * 60)
        end 
      end
      
      @timestream_by_category
    end
  end
end
