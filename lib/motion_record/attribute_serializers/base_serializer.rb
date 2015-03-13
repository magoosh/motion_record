module MotionRecord
  module AttributeSerializers
    class BaseSerializer
      # column - a Schema::ColumnDefinition object
      def initialize(column)
        @column = column
      end

      # Override this method in a subclass to define the custom serializer
      def serialize(value)
        raise "Must be implemented"
      end

      # Override this method in a subclass to define the custom serializer
      def deserialize(value)
        raise "Must be implemented"
      end
    end
  end
end
