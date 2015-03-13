module MotionRecord
  module Serialization
    module ClassMethods
      def serialize(attribute_name, serializer_class_or_sym)
        column = self.table_columns[attribute_name]

        if serializer_class_or_sym.is_a?(Symbol)
          self.serializers[attribute_name] = case serializer
          when :time
            Serialization::TimeSerializer.new(column)
          when :boolean
            Serialization::BooleanSerializer.new(column)
          when :json
            Serialization::JSONSerializer.new(column)
          else
            raise "Unknown serializer #{serializer.inspect}"
          end
        else
          self.serializers[attribute_name] = serializer_class_or_sym.new(column)
        end
      end

      def serializers
        @serializers ||= Hash.new(Serialization::DefaultSerializer.new(nil))
      end

      # Build a new object from the Hash result of a SQL query
      def from_table_params(params)
        attributes = {}
        params.each do |name, value|
          attributes[name.to_sym] = serializers[name.to_sym].deserialize(value)
        end
        record = self.new(attributes)
        record.mark_persisted!
        record
      end

      # Serialize a Hash of attributes to their database representation
      def to_table_params(hash)
        params = {}
        hash.each do |name, value|
          unless name == primary_key
            params[name] = serializers[name].serialize(value)
          end
        end
        params
      end
    end
  end
end
