# This serializer converts the object back and forth as-is
module MotionRecord
  module AttributeSerializers
    class DefaultSerializer < BaseSerializer
      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end
    end
  end
end
