module MotionRecord
  module Serialization
    class JSONParserError < StandardError; end

    class JSONSerializer < BaseSerializer

      def serialize(value)
        unless @column.type == :text
          raise "JSON can only be serialized to TEXT columns"
        end
        self.class.generate_json(value)
      end

      def deserialize(value)
        unless @column.type == :text
          raise "JSON can only be deserialized from TEXT columns"
        end
        self.class.parse_json(value)
      end

      # JSON generate/parse code is hoisted from BubbleWrap::JSON

      def self.generate_json(obj)
        NSJSONSerialization.dataWithJSONObject(obj, options:0, error:nil).to_str
      end

      def self.parse_json(str_data)
        return nil unless str_data
        data = str_data.respond_to?('dataUsingEncoding:') ? str_data.dataUsingEncoding(NSUTF8StringEncoding) : str_data
        opts = NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments
        error = Pointer.new(:id)
        obj = NSJSONSerialization.JSONObjectWithData(data, options:opts, error:error)
        raise JSONParserError, error[0].description if error[0]
        obj
      end
    end
  end
end
