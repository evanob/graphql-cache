require 'graphql'

module GraphQL
  module Cache
    class FieldExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **rest)
        key = cache_key(object, arguments, context, options[:cache])
        value = Marshal[key].read(options[:cache], force: object.context[:force_cache]) do
          yield(object, arguments)
        end

        wrap_connections(value, arguments, parent: object, context: context)
      end

      private

      def cache_key(obj, args, ctx, options)
        Key.new(obj, args, field.owner, field, ctx, options).to_s
      end

      def wrap_connections(value, args, **kwargs)
        return value unless field.connection?

        # return cached value if it is already a connection object
        # this occurs when the value is being resolved by GraphQL
        # and not being read from cache
        return value if value.class.ancestors.include?(GraphQL::Relay::BaseConnection)

        create_connection(value, args, **kwargs)
      end

      def create_connection(value, args, **kwargs)
        GraphQL::Relay::BaseConnection.connection_for_nodes(value).new(
          value,
          args,
          field: field,
          parent: kwargs[:parent],
          context: kwargs[:context]
        )
      end
    end
  end
end
