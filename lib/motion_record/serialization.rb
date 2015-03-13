module MotionRecord
  module Serialization
    module ClassMethods
      # Register a new attribute serializer
      #
      # attribute               - Symbol name of the attribute
      # serializer_class_or_sym - One of :time, :boolean, :json or a custom
      #                           subclass of Serialization::BaseSerializer
      def serialize(attribute, serializer_class_or_sym)
        if serializer_class_or_sym.is_a?(Symbol)
          self.serializer_classes[attribute] = case serializer_class_or_sym
          when :time
            Serialization::TimeSerializer
          when :boolean
            Serialization::BooleanSerializer
          when :json
            Serialization::JSONSerializer
          else
            raise "Unknown serializer #{serializer_class_or_sym.inspect}"
          end
        else
          self.serializer_classes[attribute] = serializer_class_or_sym
        end
      end

      # Build a new object from the Hash result of a SQL query
      def from_table_params(params)
        attributes = {}
        params.each do |name, value|
          attributes[name.to_sym] = serializer(name.to_sym).deserialize(value)
        end
        record = self.new(attributes)
        record.mark_persisted!
        record
      end

      # Serialize a Hash of attributes to their database representation
      def to_table_params(hash)
        hash.each_with_object({}) do |attribute_and_value, params|
          attribute, value = attribute_and_value
          params[attribute] = serializer(attribute).serialize(value)
        end
      end

      protected

      # Internal: Get the serializer object for an attribute
      #
      # attribute - Symbol name of the attribute
      def serializer(attribute)
        @serializers ||= {}
        unless @serializers[attribute]
          @serializers[attribute] = build_serializer(attribute)
        end
        @serializers[attribute]
      end

      # Internal: Registry of serializer classes 
      def serializer_classes
        @serializer_classes ||= Hash.new(Serialization::DefaultSerializer)
      end

      def build_serializer(attribute)
        serializer_classes[attribute].new(table_columns[attribute])
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
