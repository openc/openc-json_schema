module Openc
  module JsonSchema
    module Validator
      extend self

      def validate(schema_path, record)
        validator = JSON::Validator.new(
          schema_path,
          record,
          :record_errors => true,
          :errors_as_objects => true,
          :validate_schema => true
        )
        errors = validator.validate

        # For now, we just handle the first error.
        error = errors[0]
        return if error.nil?

        convert_error(extract_error(error, record, validator))
      end

      def extract_error(error, record, validator)
        if error[:failed_attribute] == 'OneOf'
          if error[:message].match(/did not match any/)
            path_elements = fragment_to_path(error[:fragment]).split('.')

            json_schema = validator.instance_variable_get(:@base_schema)
            schema = json_schema.schema

            path_elements.each do |element|
              record = record[element]
              schema = schema['properties'][element]

              if (ref = schema['$ref'])
                schema_uri = validator.absolutize_ref_uri(ref, json_schema.uri)
                json_schema = JSON::Validator.schema_reader.read(schema_uri)
                schema = json_schema.schema
              end
            end

            one_of_schemas = schema['oneOf']

            schemas_for_type_with_ix = case record
            when Hash
              one_of_schemas.each_with_index.reject {|s, ix| s['properties'].nil?}
            when String
              one_of_schemas.each_with_index.select {|s, ix| s['type'] == 'string' || (s['type'].nil? && s['properties'].nil?)}
            when Integer
              one_of_schemas.each_with_index.select {|s, ix| s['type'] == 'integer'}
            when Array
              one_of_schemas.each_with_index.select {|s, ix| s['type'] == 'array'}
            else
              raise "Unexpected type: #{record}"
            end

            case schemas_for_type_with_ix.size
            when 0
              return error
            when 1
              ix = schemas_for_type_with_ix[0][1]
              return error[:errors][:"oneof_#{ix}"][0]
            else
              if record.is_a?(Hash)
                schemas_for_type_with_ix.each do |s, ix|
                  s['properties'].each do |k, v|
                    next if v['enum'].nil?

                    if v['enum'].include?(record[k])
                      return error[:errors][:"oneof_#{ix}"][0]
                    end
                  end
                end
              else
                return error
              end
            end
          end
        end

        error
      end

      def convert_error(error)
        case error[:failed_attribute]
        when 'Required'
          match = error[:message].match(/required property of '(.*)'/)
          missing_property = match[1]
          path = fragment_to_path("#{error[:fragment]}/#{missing_property}")

          {:type => :missing, :path => path}
        when 'OneOf'
          if error[:message].match(/did not match any/)
            {:type => :one_of_no_matches, :path => fragment_to_path(error[:fragment])}
          else
            {:type => :one_of_many_matches, :path => fragment_to_path(error[:fragment])}
          end
        when 'AnyOf'
          {:type => :any_of_no_matches, :path => fragment_to_path(error[:fragment])}
        when 'MinLength'
          match = error[:message].match(/minimum string length of (\d+) in/)
          min_length = match[1].to_i
          {:type => :too_short, :path => fragment_to_path(error[:fragment]), :length => min_length}
        when 'MaxLength'
          match = error[:message].match(/maximum string length of (\d+) in/)
          max_length = match[1].to_i
          {:type => :too_long, :path => fragment_to_path(error[:fragment]), :length => max_length}
        when 'TypeV4'
          match = error[:message].match(/the following types?: ([\w\s,]+) in schema/)
          allowed_types = match[1].split(',').map(&:strip)
          {:type => :type_mismatch, :path => fragment_to_path(error[:fragment]), :allowed_types => allowed_types}
        when 'Enum'
          match = error[:message].match(/the following values: ([\w\s,]+) in schema/)
          allowed_values = match[1].split(',').map(&:strip)
          {:type => :enum_mismatch, :path => fragment_to_path(error[:fragment]), :allowed_values => allowed_values}
        when 'AdditionalProperties'
          match = error[:message].match(/contains additional properties \["(.*)"\] outside of the schema/)
          extra_properties = match[1].split('", "')
          {:type => :extra_properties, :path => fragment_to_path(error[:fragment]), :extra_properties => extra_properties}
        else
          if error[:message].match(/must be of format yyyy-mm-dd/)
            {:type => :format_mismatch, :path => fragment_to_path(error[:fragment]), :expected_format => 'yyyy-mm-dd'}
          else
            {:type => :unknown, :path => fragment_to_path(error[:fragment]), :failed_attribute => error[:failed_attribute], :message => error[:message]}
          end
        end
      end

      def fragment_to_path(fragment)
        fragment.sub(/^#?\/*/, '').gsub('/', '.')
      end
    end
  end
end
