module MotionRecord
  module Schema
    class TableDefinition
      def initialize(name, options={})
        @name = name
        @columns = []
        @index_definitions = []

        unless options.has_key?(:id) && !options[:id]
          add_default_primary_column
        end
      end

      def execute
        # Create table
        column_sql = @columns.map(&:to_sql_definition).join(", ")
        MotionRecord::Base.connection.execute "CREATE TABLE #{@name} (#{column_sql})"

        # Create table's indexes
        @index_definitions.each(&:execute)
      end

      def text(column_name, options={})
        @columns << ColumnDefinition.new(:text, column_name, options)
      end

      def integer(column_name, options={})
        @columns << ColumnDefinition.new(:integer, column_name, options)
      end

      def float(column_name, options={})
        @columns << ColumnDefinition.new(:float, column_name, options)
      end

      def index(columns, options={})
        @index_definitions << IndexDefinition.new(@name, columns, options)
      end

      # Add :created_at and :updated_at columns to the table
      def timestamps
        self.integer(:created_at)
        self.integer(:updated_at)
      end

      protected

      def add_default_primary_column
        @columns << ColumnDefinition.new(:integer, "id", primary: true)
      end
    end
  end
end
