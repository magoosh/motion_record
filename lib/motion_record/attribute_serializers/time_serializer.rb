module MotionRecord
  module AttributeSerializers
    class TimeSerializer < BaseSerializer

      # Pattern stolen from Ruby Time's xmlschema method
      ISO8601_PATTERN = /\A\s*
              (-?\d+)-(\d\d)-(\d\d)
              T
              (\d\d):(\d\d):(\d\d)
              (\.\d+)?
              (Z|[+-]\d\d:\d\d)?
              \s*\z/ix

      def serialize(value)
        case @column.type
        when :integer, :float
          value.to_i
        when :text
          self.class.time_to_iso8601(value)
        else
          raise "Can't serialize #{value.inspect} to #{@column.type.inspect}"
        end
      end

      def deserialize(value)
        case @column.type
        when :integer, :float
          Time.at(value)
        when :text
          self.class.time_from_iso8601(value)
        else
          raise "Can't deserialize #{value.inspect} from #{@column.type.inspect}"
        end
      end

      # Convert a Time object to an ISO8601 format time string
      #
      # time - the Time to convert
      #
      # Returns the String representation
      def self.time_to_iso8601(time)
        if time.utc_offset == 0
          zone = "Z"
        else
          offset_hours   = time.utc_offset / 3600
          offset_minutes = (time.utc_offset - (offset_hours * 3600)) / 60
          zone = "%+03d:%02d" % [offset_hours, offset_minutes]
        end

        if time.usec != 0
          "%04d-%02d-%02dT%02d:%02d:%02d.%03d%s" % [time.year, time.month, time.day, time.hour, time.min, time.sec, time.usec, zone]
        else
          "%04d-%02d-%02dT%02d:%02d:%02d:%s" % [time.year, time.month, time.day, time.hour, time.min, time.sec, zone]
        end
      end

      # Parse an ISO8601 format time string
      #
      # time_str - the String time representation in ISO8601 format
      #
      # Returns a Time object
      def self.time_from_iso8601(time_str)
        # Logic stolen from Ruby Time's xmlschema method
        if (match = ISO8601_PATTERN.match(time_str))
          year = match[1].to_i
          mon  = match[2].to_i
          day  = match[3].to_i
          hour = match[4].to_i
          min  = match[5].to_i
          sec  = match[6].to_i
          # usec = (match[7] || 0).to_i # microsecond values are discarded
          zone = match[8]
          if zone == "Z"
            Time.utc(year, mon, day, hour, min, sec)
          elsif zone
            Time.new(year, mon, day, hour, min, sec, zone)
          end
        else
          raise ArgumentError.new("invalid date: #{time_str.inspect}")
        end
      end
    end
  end
end
