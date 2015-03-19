# This serializer stores Time objects to TEXT columbs, but discards all
# information except for year, month, and day.
#
# (Time is used because RubyMotion doesn't currently support Date objects)

module MotionRecord
  module Serialization
    class DateSerializer < BaseSerializer

      # ISO8601 pattern that only matches date strings
      ISO8601_PATTERN = /\A\s*
              (-?\d+)-(\d\d)-(\d\d)
              \s*\z/ix

      def serialize(value)
        case @column.type
        when :text
          self.class.date_to_iso8601(value)
        else
          raise "Can't serialize #{value.inspect} to #{@column.type.inspect}"
        end
      end

      def deserialize(value)
        case @column.type
        when :text
          self.class.date_from_iso8601(value)
        else
          raise "Can't deserialize #{value.inspect} from #{@column.type.inspect}"
        end
      end

      # Convert a Time object to an ISO8601 format date string.
      #
      # time - the Time to convert
      #
      # Returns the String representation
      def self.date_to_iso8601(time)
        "%04d-%02d-%02d" % [time.year, time.month, time.day]
      end

      # Parse an ISO8601 format date string.
      #
      # date_str - the String date representation in ISO8601 format
      #
      # Returns a Time object
      def self.date_from_iso8601(date_str)
        if (match = ISO8601_PATTERN.match(date_str))
          year = match[1].to_i
          mon  = match[2].to_i
          day  = match[3].to_i
          Time.utc(year, mon, day)
        else
          raise ArgumentError.new("invalid date: #{date_str.inspect}")
        end
      end
    end
  end
end
