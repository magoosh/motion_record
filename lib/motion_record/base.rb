module MotionRecord
  class Base
    include Serialization
    include Persistence
    include ScopeHelpers

    def initialize(attributes={})
      initialize_from_attribute_hash(attributes)
    end

    def to_attribute_hash
      self.class.attribute_names.each_with_object({}) do |name, hash|
        hash[name] = self.instance_variable_get "@#{name}"
      end
    end

    def connection
      self.class.connection
    end

    protected

    def initialize_from_attribute_hash(hash)
      self.class.attribute_defaults.merge(hash).each do |name, value|
        self.instance_variable_set "@#{name}", value
      end
    end

    class << self
      # Add attribute methods to the model
      #
      # name    - Symobl name of the attribute
      # options - optional configuration Hash:
      #           :default - default value for the attribute (nil otherwise)
      def define_attribute(name, options = {})
        attr_accessor name
        self.attribute_names << name.to_sym
        if options[:default]
          self.attribute_defaults[name.to_sym] = options[:default]
        end
      end

      def attribute_names
        @attribute_names ||= []
      end

      def attribute_defaults
        @attribute_defaults ||= {}
      end

      def connection
        ConnectionAdapters::SQLiteAdapter.instance
      end
    end
  end
end
