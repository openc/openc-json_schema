module Openc
  module JsonSchema
    module Validator
      extend self

      def validate(schema_path, record)
        schema = JSON.parse(File.read(schema_path))
        errors = JSON::Validator.fully_validate(schema_path, record, :errors_as_objects => true)

        # For now, we just handle the first error.
        error = errors[0]
        return if error.nil?

        extract_error(error, record, schema)
      end

      def extract_error(error, record, schema)
        case error[:failed_attribute]
        when 'Required'
          match = error[:message].match(/required property of '(.*)'/)
          missing_property = match[1]
          path = fragment_to_path("#{error[:fragment]}/#{missing_property}")

          {:type => :missing, :path => path}
        when 'OneOf'
          if error[:message].match(/did not match any/)
            path_elements = fragment_to_path(error[:fragment]).split('.')

            sub_record = record
            sub_schema = schema

            path_elements.each do |element|
              sub_record = sub_record[element]
              sub_schema = sub_schema['properties'][element]
            end

            one_of_schemas = sub_schema['oneOf']

            unless one_of_schemas.nil?
              one_of_schemas.each_with_index do |s, i|
                s['properties'].each do |k, v|
                  next if v['enum'].nil?

                  if v['enum'].include?(sub_record[k])
                    sub_error = error[:errors][:"oneof_#{i}"][0]
                    return extract_error(sub_error, sub_record, sub_schema)
                  end
                end
              end
            end

            {:type => :one_of_no_matches, :path => fragment_to_path(error[:fragment])}
          else
            {:type => :one_of_many_matches, :path => fragment_to_path(error[:fragment])}
          end
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
