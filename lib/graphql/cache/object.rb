require 'graphql'

module GraphQL
  module Cache
    module Object
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def field(*args, cache: false, **kwargs, &block)
          super(*args, **kwargs) do
            extension(GraphQL::Cache::FieldExtension, cache: cache) if cache
            instance_eval(&block) if block_given?
          end
        end
      end
    end
  end
end
