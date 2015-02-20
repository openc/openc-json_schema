module Openc
  module JsonSchema
    module Utils
      extend self

      def load_validator(schema_path, record, options={})
        default_options = {
          :record_errors => true,
          :errors_as_objects => true,
          :validate_schema => false
        }

        validator = JSON::Validator.new(
          schema_path,
          record,
          default_options.merge(options)
        )
      end

      def extract_json_schema(validator)
        validator.instance_variable_get(:@base_schema)
      end
    end
  end
end
