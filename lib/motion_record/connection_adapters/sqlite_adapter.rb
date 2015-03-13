module MotionRecord
  module ConnectionAdapters
    class SQLiteAdapter
      class << self
        # Configure the SQLite connection
        #
        # options - Hash of configuration options for the SQLite connection
        #           :file - full name of the database file, or :memory for
        #                   in-memory database files (default is "app.sqlite3"
        #                   in the app's `/Library/Application Support` folder)
        #           :debug - set to false to turn off SQL debug logging
        def configure(options={})
          @configuration_options = options
        end

        def instance
          @instance ||= ConnectionAdapters::SQLiteAdapter.new(filename, debug?)
        end

        # Full filename of the database file
        def filename
          if (file = @configuration_options[:file])
            if file == :memory
              ":memory:"
            else
              file
            end
          else
            create_default_database_file
          end
        end

        # Returns true if debug logging is enabled for the database
        def debug?
          if @configuration_options.has_key?(:debug)
            !!@configuration_options[:debug]
          else
            true
          end
        end

        protected

        # Create the default database file in `Library/Application Support` if
        # it doesn't exist and return the file's full path
        def create_default_database_file
          fm = NSFileManager.defaultManager

          support_path = fm.URLsForDirectory(NSApplicationSupportDirectory, inDomains: NSUserDomainMask).first.path
          file_path = File.join(support_path, "app.sqlite3")

          unless fm.fileExistsAtPath(file_path)
            fm.createDirectoryAtPath(support_path, withIntermediateDirectories:true, attributes:nil, error:nil)
            success = fm.createFileAtPath(file_path, contents: nil, attributes: nil)
            raise "Couldn't create file #{path}" unless success
          end

          file_path
        end
      end

      def initialize(file, debug=true)
        @db = SQLite3::Database.new(file)
        @db.logging = debug
      end

      def execute(command)
        @db.execute(command)
      end

      def table_exists?(table_name)
        # FIXME: This statement is totally vulnerable to SQL injection
        @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{table_name}'").any?
      end

      # Load all records for a scope
      #
      # scope - A MotionRecord::Scope
      #
      # Returns an Array of row Hashes
      def select(scope)
        select_statement = "SELECT * FROM #{scope.klass.table_name} #{scope.predicate}"
        @db.execute(select_statement, scope.predicate_values)
      end

      # Add a row to a table
      #
      # table_name - name of the table
      # params     - Hash of column names to values to insert
      def insert(table_name, params)
        pairs = params.to_a
        param_names  = pairs.map(&:first)
        param_values = pairs.map(&:last)
        param_marks = Array.new(param_names.size, "?").join(", ")

        insert_statement = "INSERT INTO #{table_name} (#{param_names.join(", ")}) VALUES (#{param_marks})"

        @db.execute insert_statement, param_values
      end

      # Add a row to a table
      #
      # scope  - A MotionRecord::Scope
      # params - Hash of column names to values to update
      def update(scope, params)
        pairs = params.to_a
        param_names  = pairs.map(&:first)
        param_values = pairs.map(&:last)
        param_marks  = param_names.map { |param| "#{param} = ?" }.join(", ")

        update_statement = "UPDATE #{scope.klass.table_name} SET #{param_marks} #{scope.predicate}"

        @db.execute update_statement, param_values + scope.predicate_values
      end

      # Delete rows from a table
      #
      # scope - MotionRecord::Scope defining the set of rows to delete
      def delete(scope)
        delete_statement = "DELETE FROM #{scope.klass.table_name} #{scope.predicate}"

        @db.execute delete_statement, scope.predicate_values
      end

      # Run a calculation on a set of rows
      #
      # scope  - MotionRecord::Scope which defines the set of rows
      # method - one of :count, :maximum, :minimum, :sum, :average
      # column - name of the column to run the calculation on
      #
      # Returns the numerical value of calculation or nil if there were no rows
      # in the scope
      def calculate(scope, method, column)
        case method
        when :count
          calculation = "COUNT(#{column || "*"})"
        when :maximum
          calculation = "MAX(#{column})"
        when :minimum
          calculation = "MIN(#{column})"
        when :sum
          calculation = "SUM(#{column})"
        when :average
          calculation = "AVG(#{column})"
        else
          raise "Unrecognized calculation: #{method.inspect}"
        end

        calculate_statement = "SELECT #{calculation} AS #{method} FROM #{scope.klass.table_name} #{scope.predicate}"

        if (row = @db.execute(calculate_statement, scope.predicate_values).first)
          row[method]
        else
          nil
        end
      end

    end
  end
end
