module Openc
  module JsonSchema
    module DateConverter
      extend self

      def convert_dates(schema_path, record)
        validator = Utils.load_validator(schema_path, record)
        json_schema = Utils.extract_json_schema(validator)
        _convert_dates(record, validator, json_schema, json_schema.schema)
      end

      def _convert_dates(record, validator, json_schema, schema)
        return record if schema.nil?

        if (ref = schema['$ref'])
          schema_uri = validator.absolutize_ref_uri(ref, json_schema.uri)
          json_schema = JSON::Validator.schema_reader.read(schema_uri)
          schema = json_schema.schema
        end

        case record
        when Hash
          pairs = record.map do |k, v|
            properties = schema['properties']
            if properties.nil?
              [k, v]
            else
              [k, _convert_dates(v, validator, json_schema, properties[k])]
            end
          end
          Hash[pairs]
        when Array
          record.map {|e| _convert_dates(e, validator, json_schema, schema['items'])}
        else
          if schema['format'] == 'date'
            begin
              Date.strptime(record, '%Y-%m-%d').strftime('%Y-%m-%d')
            rescue ArgumentError
              record
            end
          else
            record
          end
        end
      end
    end
  end
end
