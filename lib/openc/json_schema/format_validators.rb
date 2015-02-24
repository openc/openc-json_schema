require 'date'

date_format_validator = -> value {
  begin
    Date.strptime(value, '%Y-%m-%d')
  rescue ArgumentError
    raise JSON::Schema::CustomFormatError.new('must be of format yyyy-mm-dd')
  end
}

JSON::Validator.register_format_validator('date', date_format_validator)

non_blank_format_validator = -> value {
  raise JSON::Schema::CustomFormatError.new('must not be blank') if value.strip == ''
}

JSON::Validator.register_format_validator('non-blank', non_blank_format_validator)
