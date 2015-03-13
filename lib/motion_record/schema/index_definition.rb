module MotionRecord
  module Schema
    class IndexDefinition

      # Initialize the index definition
      #
      # table_name - name of the table
      # columns    - either the String name of the column to index or an Array
      #              of column names
      # options    - optional Hash of options for the index
      #              :unique - set to true to create a unique index
      #              :name - provide a String to override the default index name
      def initialize(table_name, columns, options={})
        @table_name = table_name
        @columns = columns.is_a?(Array) ? columns : [columns]

        @name    = options[:name] || build_name_from_columns
        @unique  = !!options[:unique]
      end

      # Add the index to the database
      def execute
        index_statement = "CREATE#{' UNIQUE' if @unique} INDEX #{@name} ON #{@table_name} (#{@columns.join ", "})"

        MotionRecord::Base.connection.execute index_statement
      end

      protected

      def build_name_from_columns
        "index_#{@table_name}_on_#{@columns.join "_and_"}"
      end
    end
  end
end
