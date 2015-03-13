# A model for building scoped database queries
#

module MotionRecord
  class Scope

    attr_reader :klass
    attr_reader :conditions

    def initialize(klass, options = {})
      @klass = klass
      @conditions = options[:conditions] || {} # TODO: freeze?
      @order = options[:order]
      @limit = options[:limit]
    end

    # Scope builder

    def where(conditions={})
      Scope.new(@klass, :conditions => @conditions.merge(conditions), :order => @order, :limit => @limit)
    end

    def order(ordering_term)
      Scope.new(@klass, :conditions => @conditions, :order => ordering_term, :limit => @limit)
    end

    def limit(limit_value)
      Scope.new(@klass, :conditions => @conditions, :order => @order, :limit => limit_value)
    end

    # Read-only queries

    def exists?
      count > 0
    end

    def first
      limit(1).find_all.first
    end

    def find(id)
      self.where(@klass.primary_key => id).first
    end

    def find_all
      connection.select(self).map { |row| @klass.from_table_params(row) }
    end

    def pluck(attribute)
      connection.select(self).map { |row| row[attribute] }
    end

    # Persistence queries

    def update_all(params)
      connection.update(self, params)
    end

    def delete_all
      connection.delete(self)
    end

    # Calculations

    def count(column=nil)
      calculate(:count, column)
    end

    def maximum(column)
      calculate(:maximum, column)
    end

    def minimum(column)
      calculate(:minimum, column)
    end

    def sum(column)
      calculate(:sum, column)
    end

    def average(column)
      calculate(:average, column)
    end

    # SQL helpers

    def predicate?
      predicate_segments.any?
    end

    def predicate
      predicate_segments.join(" ")
    end

    def predicate_values
      condition_columns.map { |column| @conditions[column] }
    end

    protected

    def calculate(method, column)
      connection.calculate(self, method, column)
    end

    def predicate_segments
      unless @predicate_segments
        @predicate_segments = []
        if condition_columns.any?
          @predicate_segments << "WHERE #{condition_columns.map { |c| "#{c} = ? " }.join " AND "}"
        end
        if @order
          @predicate_segments << "ORDER BY #{@order}"
        end
        if @limit
          @predicate_segments << "LIMIT #{@limit}"
        end
      end
      @predicate_segments
    end

    def condition_columns
      @condition_columns ||= @conditions.keys
    end

    def connection
      Base.connection
    end
  end
end
