# These helper methods make it possible to call scope methods like `where` and
# `find` directly on MotionRecord::Base classes
#
# Example:
#
#    Event.where(:name => "launched").find_all
#
# FIXME: MotionRecord::Persistence includes this module, but the normal file
# ordering breaks the dependency
module MotionRecord
  module ScopeHelpers
    module ClassMethods

      # Read-only queries

      def exists?
        scoped.exists?
      end

      def first
        scoped.first
      end

      def find(id)
        scoped.find(id)
      end

      def find_all
        scoped.find_all
      end

      def pluck(attribute)
        scoped.pluck(attribute)
      end

      # Persistence queries

      def update_all(params)
        scoped.update_all(params)
      end

      def delete_all
        scoped.delete_all
      end

      # Calculations

      def count(column=nil)
        scoped.count(column)
      end

      def maximum(column)
        scoped.maximum(column)
      end

      def minimum(column)
        scoped.minimum(column)
      end

      def sum(column)
        scoped.sum(column)
      end

      def average(column)
        scoped.average(column)
      end

      # Scope building

      def where(conditions={})
        scoped.where(conditions)
      end

      def order(ordering_term)
        scoped.order(ordering_term)
      end

      def limit(limit_value)
        scoped.limit(limit_value)
      end

      protected

      def scoped
        Scope.new(self)
      end
    end
  end
end
