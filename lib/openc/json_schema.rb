require 'json-schema'

require 'openc/json_schema/validator'
require 'openc/json_schema/format_validators'

module Openc
  module JsonSchema
    extend self

    def validate(schema_or_filename, schema_dir, record)
      Validator.validate(schema_or_filename, schema_dir, record)
    end
  end
end
