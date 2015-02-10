require 'simplecov'
SimpleCov.start

require 'openc/json_schema'

def get_error(schema_or_path, record)
  case schema_or_path
  when Hash
    json_data = schema_or_path.to_json
    filename = Digest::MD5.hexdigest(json_data) + '.json'
    schema_path = File.join('spec', 'tmp', filename)
    File.open(schema_path, 'w') {|f| f.write(json_data)}
  when String
    schema_path = schema_or_path
  else
    raise
  end

  error = Openc::JsonSchema.validate(schema_path, record)
end

RSpec::Matchers.define(:fail_validation_with) do |expected|
  match do |actual|
    schema_or_path, record = actual
    @error = get_error(schema_or_path, record)
    expect(@error).to eq(expected)
  end

  failure_message do |actual|
    "Expected error to be #{expected}, but was #{@error}"
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |actual|
    schema_or_path, record = actual
    error = get_error(schema_or_path, record)
    expect(error).to eq(nil)
  end
end
