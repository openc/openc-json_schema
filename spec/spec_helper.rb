require "simplecov"
require "coveralls"
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter "spec"
end

require 'openc/json_schema'

RSpec::Matchers.define(:fail_validation_with) do |expected|
  match do |(schema_or_path, record)|
    @actual = Openc::JsonSchema.validate(schema_or_path, record)
    expect(@actual).to_not be(nil)
    expect(@actual[:message]).to eq(expected)
  end

  failure_message do |actual|
    if actual.nil?
      "Expected error, but there was none"
    else
      "Expected error to be #{expected}, but was #{actual}"
    end
  end
end

RSpec::Matchers.define(:be_valid) do
  match do |(schema_or_path, record)|
    error = Openc::JsonSchema.validate(schema_or_path, record)
    expect(error).to eq(nil)
  end
end

RSpec::Matchers.define(:convert_dates_to) do |expected|
  match do |(schema_or_path, record)|
    converted_record = Openc::JsonSchema.convert_dates(schema_or_path, record)
    expect(converted_record).to eq(expected)
  end
end
