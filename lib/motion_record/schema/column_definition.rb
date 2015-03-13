module MotionRecord
  module Schema
    class ColumnDefinition
      TYPE_MAP = {
        :integer => "INTEGER",
        :text    => "TEXT",
        :float   => "REAL"
      }
      INVERSE_TYPE_MAP = {
        "INTEGER" => :integer,
        "TEXT"    => :text,
        "REAL"    => :float
      }

      attr_reader :type
      attr_reader :name
      attr_reader :options
      
      # name    - name of the column
      # type    - a Symbol representing the column type
      # options - Hash of constraints for the column:
      #           :primary - set to true to configure as the primary auto-incrementing key
      #           :null - set to false to add a "NOT NULL" constraint
      #           :default - TODO
      def initialize(type, name, options)
        @type = type.to_sym
        @name = name.to_sym
        @options = options
      end

      def to_sql_definition
        [@name, sql_type, sql_options].compact.join(" ")
      end

      def default
        @options[:default]
      end

      # Build a new ColumnDefinition from the result of a "PRAGMA table_info()"
      # query
      #
      # pragma - Hash representing a row of the query's result:
      #          :cid - column index
      #          :name - column name
      #          :type - column type
      #          :notnull - integer flag for "NOT NULL"
      #          :dflt_value - default value
      #          :pk - integer flag for primary key
      #
      # Returns the new ColumnDefinition
      def self.from_pragma(pragma)
        type = INVERSE_TYPE_MAP[pragma[:type]]
        options = {
          :null    => (pragma[:notnull] != 1),
          :primary => (pragma[:pk] == 1),
          :default => (pragma[:dflt_value])
        }

        if options[:default]
          case type
          when :integer
            options[:default] = options[:default].to_i
          when :float
            options[:default] = options[:default].to_f
          end
        end

        self.new(type, pragma[:name], options)
      end

      protected

      def sql_type
        if TYPE_MAP[@type]
          TYPE_MAP[@type]
        else
          raise "Unrecognized column type: #{@type.inspect}"
        end
      end

      def sql_options
        sql_options = []

        @options.each do |key, value|
          case key
          when :primary
            if value
              sql_options << "PRIMARY KEY ASC AUTOINCREMENT"
            end
          when :null
            if !value
              sql_options << "NOT NULL"
            end
          when :default
            if value
              sql_options << "DEFAULT #{value.inspect}"
            end
          else
            raise "Unrecognized column option: #{key.inspect}"
          end
        end

        if sql_options.any?
          sql_options.join(" ")
        else
          nil
        end
      end
    end
  end
end
