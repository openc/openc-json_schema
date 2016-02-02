require 'json-pointer'
require 'json-schema'

require 'openc/json_schema/date_converter'
require 'openc/json_schema/format_validators'
require 'openc/json_schema/utils'
require 'openc/json_schema/validator'
require 'openc/json_schema/version'

module Openc
  module JsonSchema
    extend self

    def validate(schema_path, record)
      Validator.validate(schema_path, record)
    end

    def convert_dates(schema_path, record)
      DateConverter.convert_dates(schema_path, record)
    end
  end
end
