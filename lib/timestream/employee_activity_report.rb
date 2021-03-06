require 'rubygems'
require 'spreadsheet'
require 'terminal-table/import'

module Timestream
  class EmployeeActivityReport
    ACTIVITY_COLUMN = 2
    
    DATE_COLUMN = 1
    DATE_ROW = 2
    
    DAY_COLUMN_SPAN = 3
    
    def date_column(date)
      slot = date_slot(date)
      slot_column(slot)
    end
    
    def date_slot(date)
      day_delta = (date - saturday).to_i
      
      case day_delta
        # Saturday and Sunday map to weekend
        when 0..1
          0
        # All others map to their own day
        when 2..6
          day_delta - 1
        else
          raise ArgumentError, "#{date} is not in the same week as #{saturday}"
      end
    end
    
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
    
    def slot_column(slot)
      9 + (slot * DAY_COLUMN_SPAN)
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
    
    def updateFromHamster(hamster)
      # Categories in Hamster are mapped to Activities in EAR
      
      hamster.timestream_by_category.each do |category, timestream|
        # XXX should this been creating EAR Timestreams instead of updating rows directly?
        (12 .. 36).each do |row_index|
          row = self.row(row_index)
          activity = row[ACTIVITY_COLUMN]
          
          # XXX Category is assumed to be a substring of Activity since Activity is very wordy.
          if activity and activity.include? category
            timestream.each do |date, hours|
              column = self.date_column(date)
              row[column] ||= 0
              row[column] += hours
            end
          end
        end
      end
    end
    
    def updateFromHamster!(hamster)
      updateFromHamster(hamster)
      
      # spreadsheet library recommends not writing back to same file, write to
      # temporary file and then rename that file to original.
      temporary_path = "#{path}.timestream"
      spreadsheet.write(temporary_path)
      File.rename(temporary_path, path)
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
