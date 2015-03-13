module MotionRecord
  module AttributeSerializers
    class BooleanSerializer < BaseSerializer

      def serialize(value)
        if @column.type == :integer
          value ? 1 : 0
        else
          raise "Can't serialize #{value.inspect} to #{@column.type.inspect}"
        end
      end

      def deserialize(value)
        if @column.type == :integer
          if value == 0 || value.nil?
            false
          else
            true
          end
        else
          raise "Can't deserialize #{value.inspect} from #{@column.type.inspect}"
        end
      end
    end
  end
end
