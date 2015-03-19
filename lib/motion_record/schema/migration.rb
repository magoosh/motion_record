# MotionRecord::Schema::Migration represents versions of migrations which have
# been run

module MotionRecord
  module Schema
    class Migration < Base
      class << self
        def table_name
          "schema_migrations"
        end

        def table_exists?
          connection.table_exists?(table_name)
        end

        def primary_key
          nil
        end

        def create_table
          table = Schema::TableDefinition.new(table_name, id: false)
          table.integer :version, :null => false
          table.index :version, :unique => true
          table.execute
        end
      end
    end
  end
end
