require 'json-schema'

require 'openc/json_schema/validator'
require 'openc/json_schema/format_validators'

module Openc
  module JsonSchema
    extend self

    def validate(schema_path, record)
      Validator.validate(schema_path, record)
    end
  end
end
