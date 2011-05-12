require 'rubygems'
require 'spreadsheet'
require 'terminal-table/import'

module Timestream
  class EmployeeActivityReport
    class Cell
      attr_reader :column
      
      def initialize(row, column)
        @column = column
        @row = row
      end
      
      attr_reader :row
    end
    
    def cell(location)
      worksheet.row(location.row)[location.column]
    end
    
    DATE_CELL = Cell.new(2, 1)
    
    DAY_COLUMN_SPAN = 3
    
    def initialize(path)
      @path = path
    end
    
    attr_reader :path
    
    def row(index)
      worksheet.row(index)
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
    
    def to_text_table
      employee_activity_report = self
      table {
        self.headings = ['Project Number']
        self.headings.concat Timestream::SLOT_NAMES.collect { |name|
          name.to_s.capitalize
        }
        
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
