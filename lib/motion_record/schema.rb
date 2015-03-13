module MotionRecord
  module Schema
    # Define and run all pending migrations (should be done during app setup)
    #
    # options - Hash of configuration options for the SQLite connection
    #           :file - full name of the database file, or :memory for in-memory
    #                   database files (default is "app.sqlite3" in the app's
    #                   `/Library/Application Support` folder)
    #           :debug - set to false to turn off SQL debug logging
    #
    # Example:
    #   
    #     MotionRecord::Schema.up! do
    #       migration 1, "Create events table" do
    #         create_table "events" do |t|
    #           t.text :name, :null => false
    #           t.text :properties
    #         end
    #       end
    #   
    #       migration 2, "Index events table" do
    #         add_index "events", "name", :unique => true
    #       end
    #     end
    #
    def self.up!(options={}, &block)
      ConnectionAdapters::SQLiteAdapter.configure(options)

      definition = Schema::MigratorDefinition.new
      definition.instance_eval &block

      Schema::Migrator.new(definition.migrations).run
    end
  end
end
