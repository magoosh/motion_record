module MotionRecord
  module Persistence

    TIMESTAMP_COLUMNS = [:created_at, :updated_at]

    def save!
      persist!
    end

    def delete!
      if persisted?
        self.class.where(primary_key_condition).delete_all
      else
        raise "Can't delete unpersisted records"
      end
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

    protected

    def persist!
      # HACK: Must ensure that attribute definitions are loaded from the table
      self.class.table_columns

      self.apply_persistence_timestamps
      params = self.to_attribute_hash.reject { |k, _v| k == self.class.primary_key }
      table_params = self.class.serialize_table_params(params)

      if persisted?
        self.class.where(primary_key_condition).update_all(table_params)
      else
        connection.insert self.class.table_name, table_params
      end

      self.mark_persisted!
    end

    # Update persistence auto-timestamp attributes
    def apply_persistence_timestamps
      self.updated_at   = Time.now if self.class.attribute_names.include?(:updated_at)
      self.created_at ||= Time.now if self.class.attribute_names.include?(:created_at)
    end

    def primary_key_condition
      {self.class.primary_key => self.instance_variable_get("@#{self.class.primary_key}")}
    end

    module ClassMethods
      def create!(attributes={})
        self.new(attributes).save!
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

        if TIMESTAMP_COLUMNS.include?(column.name)
          serialize column.name, :time
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
