require "sequel/model"
module Delayed
  module Serialization
    module Sequel

      module ClassMethods
        def search_path
          search_path_str = self.db["SHOW search_path"].get
          search_path_str.split(/[\s,]+/).map{|s| s.gsub(/\A"|"\z/, '')}.map(&:to_sym)
        end

        def use_search_path(search_path, &block)
          self.db.synchronize do
            previous_search_path = search_path
            begin
              set_search_path(search_path)
              yield
            ensure
              set_search_path(previous_search_path)
            end
          end
        end

      private

        def set_search_path(search_path)
          placeholders = search_path.map{'?'}.join(', ')
          placeholders = "''" if placeholders.empty?
          self.db["SET search_path TO #{placeholders}", *search_path].get
        end

      end
      module InstanceMethods

        def search_path
          self.class.search_path
        end

        def use_search_path(search_path, &block)
          self.class.use_search_path(search_path, &block)
        end

        def postgres?
          self.class.db.database_type == :postgres
        end

        def encode_with(coder)
          coder["values"] = @values
          coder["search_path"] = search_path if postgres?
        end

        def init_with(coder)
          @values = coder["values"]
          if postgres? && coder["search_path"]
            use_search_path(coder["search_path"]) { reload }
          else
            reload
          end
        rescue ::Sequel::Error
          raise Delayed::DeserializationError, "Sequel Record not found, class: #{self.class.name} , primary key: #{pk}"
        end
      end
    end
  end
end

Sequel::Model.plugin Delayed::Serialization::Sequel
