require 'json-pointer'
require 'json-schema'

require 'json_validation'
require 'openc_json_schema_formats'

require 'openc/json_schema/date_converter'
require 'openc/json_schema/format_validators'
require 'openc/json_schema/utils'
require 'openc/json_schema/validator'
require 'openc/json_schema/version'

module Openc
  module JsonSchema
    extend self

    def validate(schema, record)
      if schema.is_a?(String)
        validator = JsonValidation.load_validator(schema)
      else
        validator = JsonValidation.build_validator(schema)
      end
      fast_validation_ok = validator.validate(record)
      if fast_validation_ok
        nil
      else
        # Currently JsonValidation doesn't support error messages,
        # just returns true or false; so on a failure, we have to fall
        # back to the slower version
        Validator.validate(schema, record)
      end
    end

    def convert_dates(schema_path, record)
      DateConverter.convert_dates(schema_path, record)
    end
  end
end
