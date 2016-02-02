module Openc
  module JsonSchema
    module Validator
      extend self

      def validate(schema_path, record)
        validator = Utils.load_validator(schema_path, record)
        errors = validator.validate

        # For now, we just handle the first error.
        error = errors[0]
        return if error.nil?

        convert_error(extract_error(error, record, validator))
      end

    private

      # Returns the value of the `oneOf` keyword that is within the given schema
      # at the given path.
      #
      # @param [Hash] schema a schema
      # @param [Array<String>] path a path, based on a JSON Pointer
      # @return [Array<Hash>] the value of the `oneOf` keyword
      def walk_schema(schema, path)
        if schema.key?('oneOf')
          schema['oneOf']
        elsif schema.key?('properties')
          walk_schema(schema['properties'].fetch(path.shift), path)
        elsif schema.key?('items')
          walk_schema(schema['items'], path.drop(1))
        end
      end

      def extract_error(error, record, validator)
        if error[:failed_attribute] == 'OneOf'
          if error[:message].match(/did not match any/)
            record = JsonPointer.new(record, error[:fragment][1..-1]).value
            schema = JSON::Validator.schema_for_uri(error[:schema]).schema

            path = fragment_to_path(error[:fragment]).split('.')
            one_of = walk_schema(schema, path).each_with_index

            # Try to report errors for relevant `oneOf` schemas only.
            schemas_matching_type = case record
            when Hash
              one_of.select{|schema, _| schema.key?('properties')}
            when String
              one_of.select{|schema, _| schema['type'] == 'string' || schema['type'].nil? && schema['properties'].nil?}
            when Integer
              one_of.select{|schema, _| schema['type'] == 'integer'}
            when Array
              one_of.select{|schema, _| schema['type'] == 'array'}
            else
              raise "Unexpected type: #{record}"
            end

            matches = schemas_matching_type.size

            if matches == 1
              i = schemas_matching_type[0][1]
              return error[:errors][:"oneof_#{i}"][0]
            end

            if matches > 1 && record.is_a?(Hash)
              schemas_matching_type.each do |schema, i|
                schema['properties'].each do |key, value|
                  if value['enum'] && value['enum'].include?(record[key])
                    return error[:errors][:"oneof_#{i}"][0]
                  end
                end
              end
            end
          end
        end

        error
      end

      def convert_error(error)
        path = fragment_to_path(error[:fragment])
        extra_params = {}

        case error[:failed_attribute]
        when 'Required'
          match = error[:message].match(/required property of '(.*)'/)
          missing_property = match[1]
          path = fragment_to_path("#{error[:fragment]}/#{missing_property}")
          type = :missing
          message = "Missing required property: #{path}"

        when 'AdditionalProperties'
          match = error[:message].match(/contains additional properties \["(.*)"\] outside of the schema/)
          additional_property = match[1].split('", "')[0]
          path = fragment_to_path("#{error[:fragment]}/#{additional_property}")
          type = :additional
          message = "Disallowed additional property: #{path}"

        when 'OneOf'
          if error[:message].match(/did not match any/)
            type = :one_of_no_matches
            message = "No match for property: #{path}"
          else
            type = :one_of_many_matches
            message = "Multiple possible matches for property: #{path}"
          end

        when 'AnyOf'
          type = :any_of_no_matches
          message = "No match for property: #{path}"

        when 'MinLength'
          match = error[:message].match(/minimum string length of (\d+) in/)
          min_length = match[1].to_i
          type = :too_short
          message = "Property too short: #{path} (must be at least #{min_length} characters)"
          extra_params = {:length => min_length}

        when 'MaxLength'
          match = error[:message].match(/maximum string length of (\d+) in/)
          max_length = match[1].to_i
          type = :too_long
          message = "Property too long: #{path} (must be at most #{max_length} characters)"
          extra_params = {:length => max_length}

        when 'TypeV4'
          match = error[:message].match(/the following types?: ([\w\s,]+) in schema/)
          allowed_types = match[1].split(',').map(&:strip)
          type = :type_mismatch
          message = "Property of wrong type: #{path} (must be of type #{allowed_types.join(', ')})"
          extra_params = {:allowed_types => allowed_types}

        when 'Enum'
          match = error[:message].match(/the following values: ([\w\s,]+) in schema/)
          allowed_values = match[1].split(',').map(&:strip)
          type = :enum_mismatch
          if allowed_values.size == 1
            message = "Property must have value #{allowed_values[0]}: #{path}"
          else
            message = "Property not an allowed value: #{path} (must be one of #{allowed_values.join(', ')})"
          end
          extra_params = {:allowed_values => allowed_values}

        else
          if error[:message].match(/must be of format yyyy-mm-dd/)
            type = :format_mismatch
            message = "Property not of expected format: #{path} (must be of format yyyy-mm-dd)"
            extra_params = {:expected_format => 'yyyy-mm-dd'}
          elsif error[:message].match(/must not be blank/)
            type = :format_mismatch
            message = "Property not of expected format: #{path} (must not be blank)"
          else
            type = :unknown
            message = "Error of unknown type: #{path} (#{error[:message]})"
          end
        end

        {:type => type, :path => path, :message => message}.merge(extra_params)
      end

      def fragment_to_path(fragment)
        fragment.sub(/^#?\/*/, '').gsub('/', '.')
      end
    end
  end
end
