require 'openc/json_schema'

def get_error(schema_or_path, record)
  case schema_or_path
  when Hash
    json_data = schema_or_path.to_json
    filename = Digest::MD5.hexdigest(json_data) + '.json'
    schema_dir = "spec/tmp"
    File.open(File.join(schema_dir, filename), 'w') {|f| f.write(json_data)}
    schema_or_filename = schema_or_path
  when String
    schema_or_filename = File.basename(schema_or_path)
    schema_dir = File.dirname(schema_or_path)
  else
    raise
  end

  error = Openc::JsonSchema.validate(schema_or_filename, schema_dir, record)
end

RSpec::Matchers.define(:fail_validation_with) do |expected|
  match do |actual|
    schema_or_path, record = actual
    error = get_error(schema_or_path, record)
    expect(error).to eq(expected), "Expected #{expected}, received #{error}"
  end

  failure_message do |actual|
    schema_or_path, record = actual
    error = get_error(schema_or_path, record)
    "Expected error to be #{expected}, but was #{error}"
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |actual|
    schema_or_path, record = actual
    error = get_error(schema_or_path, record)
    expect(error).to eq(nil)
  end
end
