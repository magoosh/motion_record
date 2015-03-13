# DSL helper for defining migrations
module MotionRecord
  module Schema
    class MigratorDefinition
      attr_reader :migrations

      def initialize
        @migrations = []
      end    

      def migration(version, name=nil, &block)
        migration_definition = Schema::MigrationDefinition.new(version, name)
        migration_definition.instance_eval &block
        @migrations << migration_definition
      end
    end
  end
end
