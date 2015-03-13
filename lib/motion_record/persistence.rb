module MotionRecord
  module Persistence

    def save!
      if persisted?
        self.class.where(primary_key_condition).update_all(self.to_db_params)
      else
        connection.insert self.class.table_name, to_db_params
      end
      mark_persisted!
    end

    def delete!
      if persisted?
        self.class.where(primary_key_condition).delete_all
      else
        raise "Can't delete unpersisted records"
      end
    end

    def to_db_params
      self.class.table_columns.values.each_with_object({}) do |column, params|
        unless column.name == self.class.primary_key
          value = self.instance_variable_get "@#{column.name}"
          serializer = self.class.serializers[column.name].new(column)
          params[column.name] = serializer.serialize(value)
        end
      end
    end

    def primary_key_condition
      {self.class.primary_key => self.instance_variable_get("@#{self.class.primary_key}")}
    end

    def persisted?
      !!@persisted
    end

    def mark_persisted!
      @persisted = true
    end

    def mark_unpersisted!
      @persisted = false
    end

    module ClassMethods
      include MotionRecord::ScopeHelpers::ClassMethods

      def create!(attributes={})
        self.new(attributes).save!
      end

      def serialize(attribute_name, serializer)
        if serializer.is_a?(Symbol)
          self.serializers[attribute_name] = case serializer
          when :time
            AttributeSerializers::TimeSerializer
          when :boolean
            AttributeSerializers::BooleanSerializer
          when :json
            AttributeSerializers::JSONSerializer
          else
            raise "Unknown serializer #{serializer.inspect}"
          end
        else
          self.serializers[attribute_name] = serializer_class
        end
      end

      def serializers
        @serializers ||= Hash.new(AttributeSerializers::DefaultSerializer)
      end

      # Build a new object from the Hash result of a SQL query
      def from_table_row(hash)
        deserialized_hash = {}
        hash.each do |column_name, value|
          serializer = self.serializers[column_name].new(self.table_columns[column_name])
          deserialized_hash[column_name] = serializer.deserialize(value)
        end
        record = self.new(deserialized_hash)
        record.mark_persisted!
        record
      end

      # Sybmol name of the primary key column
      def primary_key
        :id
      end

      def table_name
        # HACK: poor-man's .pluralize
        self.to_s.downcase + "s"
      end

      def table_columns
        unless @table_columns
          @table_columns = get_columns_from_schema.each_with_object({}) do |column, hash|
            hash[column.name] = column
          end
          @table_columns.values.each do |column|
            define_attribute_from_column(column)
          end
        end
        @table_columns
      end

      protected

      # Internal: Fetch column definitions from the database
      def get_columns_from_schema
        pragma_columns = connection.execute "PRAGMA table_info(#{table_name});"
        pragma_columns.map { |p| Schema::ColumnDefinition.from_pragma(p) }
      end

      # Interal: Set up setter/getter methods to correspond with a table column
      def define_attribute_from_column(column)
        # TODO: handle options
        define_attribute column.name, default: column.default
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
