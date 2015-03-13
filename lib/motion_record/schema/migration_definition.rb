module MotionRecord
  module Schema
    class MigrationDefinition
      attr_reader :version
      attr_reader :name

      def initialize(version, name = nil)
        @version = version.to_i
        @name = name || "Migration ##{@version}"
        @definitions = []
      end

      def execute
        @definitions.each(&:execute)
      end

      def create_table(name, options = {})
        table_definition = TableDefinition.new(name, options)

        if block_given?
          yield table_definition
        end

        @definitions << table_definition
      end

      def add_index(name, columns, options = {})
        @definitions << IndexDefinition.new(name, columns, options)
      end
    end
  end
end
