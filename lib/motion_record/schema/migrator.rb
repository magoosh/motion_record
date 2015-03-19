module MotionRecord
  module Schema
    class Migrator

      attr_reader :migrations

      def initialize(migrations)
        @migrations = migrations
        @migrated_versions = nil

        initialize_schema_table
      end

      def run
        pending_migrations.each do |migration|
          migration.execute
          @migrated_versions << migration.version
          Schema::Migration.create(version: migration.version)
        end 
      end

      def pending_migrations
        @migrations.reject { |migration| migrated.include?(migration.version) }
      end

      def migrated
        @migrated_versions ||= Schema::Migration.pluck(:version).sort
      end

      protected

      def initialize_schema_table
        unless Schema::Migration.table_exists?
          Schema::Migration.create_table
        end
      end
    end
  end
end
