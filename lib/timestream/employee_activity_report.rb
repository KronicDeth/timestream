require 'rubygems'
require 'spreadsheet'
require 'terminal-table/import'

module Timestream
  class EmployeeActivityReport
    DATE_COLUMN = 1
    DATE_ROW = 2
    
    DAY_COLUMN_SPAN = 3
    
    def initialize(path)
      @path = path
    end
    
    attr_reader :path
    
    def row(index)
      worksheet.row(index)
    end
    
    def saturday
      @saturday ||= worksheet.row(DATE_ROW)[DATE_COLUMN]
    end
    
    def spreadsheet
      @spreadsheet ||= Spreadsheet.open path
    end
    
    class Timestream
      include Enumerable
      
      SLOT_NAMES = [:weekend, :monday, :tuesday, :wednesday, :thursday, :friday]
      
      def each(&block)
        @totals.each(&block)
      end
      
      def initialize
        @totals = Array.new(SLOT_NAMES.length, 0)
      end
      
      def [](day)
        if day.is_a? Symbol
          day = SLOT_NAMES.index(day)
        end
        
        @totals[day]
      end
      
      def []=(day, total)
        if day.is_a? Symbol
          day = SLOT_NAMES.index(day)
        end
        
        @totals[day] = total
      end
      
      def to_a
        @totals.dup
      end
    end
    
    def timestream_by_project_number
      if @timestream_by_project_number.nil?
        parse
      end
      
      @timestream_by_project_number
    end
    
    def to_text_table(date_format=:day_of_week)
      employee_activity_report = self
      
      table {
        self.headings = ['Project Number']
        
        case date_format
          when :day_of_week
            date_format = "%A"
          when :erp
            date_format = "%a %m/%d"
        end
         
        Timestream::SLOT_NAMES.each_index do |sunday_offset|
          # XXX assign weekend activity to sunday to simplify math
          sunday = employee_activity_report.saturday + 1
          slot_date = sunday + sunday_offset
           
          self.headings << slot_date.strftime(date_format)
        end
        
        employee_activity_report.timestream_by_project_number.each do |project_number, timestream|
          row = [project_number]
          timestream.each do |daily_total|
            row << "%02.02f" % daily_total
          end
          
          add_row row
        end 
      }
    end
    
    def worksheet
      @worksheet ||= spreadsheet.worksheet "EAR - Current Week"
    end
    
    private
    
    def parse
      @timestream_by_project_number = Hash.new { |hash, project_number|
        hash[project_number] = Timestream.new
      }
      
      (12 .. 36).each do |row_index|
        row = self.row(row_index)
        project_number = row[PROJECT_NUMBER_COLUMN]
        
        # TODO handle Vacation / Holiday / Sick time
        # no project number assigned
        next if project_number.nil?
        
        # 0 - Weekend
        # 1 - Monday
        # 2 - Tuesday...
        (0 .. 5).each do |day_index|
          timestream = @timestream_by_project_number[project_number]
          
          day_column = 9 + DAY_COLUMN_SPAN * day_index
          hours = row[day_column] || 0
          
          timestream[day_index] += hours
        end
      end
    end
    
    PROJECT_NUMBER_COLUMN = 0
  end
end
