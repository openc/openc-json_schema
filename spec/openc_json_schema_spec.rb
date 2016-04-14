require 'spec_helper'

describe Openc::JsonSchema do
  describe '.validate' do
    specify 'when record is valid' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
      }
      record = {'aaa' => 'zzz'}

      expect([schema, record]).to be_valid
    end

    specify 'when required top-level property missing' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
      }
      record = {}
      error = 'Missing required property: aaa'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when required nested property missing' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'required' => ['aaa'],
        'properties' => {
          'aaa' => {
            'type' => 'object',
            'required' => ['bbb'],
          }
        }
      }
      record = {'aaa' => {}}
      error = 'Missing required property: aaa.bbb'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when additional properties are present but disallowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'number'}
        },
        'additionalProperties' => false
      }

      record = {'aaa' => 1, 'bbb' => 2, 'ccc' => 3}

      error = 'Disallowed additional property: bbb'
      expect([schema, record]).to fail_validation_with(error)
    end

    context 'when none of oneOf options match' do
      specify 'and we are switching on an enum field' do
        schema = {
          '$schema' => 'http://json-schema.org/draft-04/schema#',
          'type' => 'object',
          'required' => ['aaa'],
          'properties' => {
            'aaa' => {
              'type' => 'object',
              'oneOf' => [{
                'properties' => {
                  'a_type' => {
                    'enum' => ['a1']
                  },
                  'a_properties' => {
                    'type' => 'object',
                    'required' => ['bbb'],
                  }
                }
              }, {
                'properties' => {
                  'a_type' => {
                    'enum' => ['a2']
                  },
                  'a_properties' => {
                    'type' => 'object',
                    'required' => ['ccc']
                  }
                }
              }]
            }
          }
        }

        record = {'aaa' => {'a_type' => 'a1', 'a_properties' => {}}}

        error = 'Missing required property: aaa.a_properties.bbb'
        expect([schema, record]).to fail_validation_with(error)
      end

      specify 'and we are switching on a nested enum field' do
        schema = {
          '$schema' => 'http://json-schema.org/draft-04/schema#',
          'type' => 'object',
          'properties' => {
            'xxx' => {
              'type' => 'object',
              'properties' => {
                'aaa' => {
                  'type' => 'object',
                  'oneOf' => [{
                    'properties' => {
                      'a_type' => {
                        'enum' => ['a1']
                      },
                      'a_properties' => {
                        'type' => 'object',
                        'required' => ['bbb'],
                      }
                    }
                  }, {
                    'properties' => {
                      'a_type' => {
                        'enum' => ['a2']
                      },
                      'a_properties' => {
                        'type' => 'object',
                        'required' => ['ccc']
                      }
                    }
                  }]
                }
              }
            }
          }
        }

        record = {'xxx' => {'aaa' => {'a_type' => 'a1', 'a_properties' => {}}}}

        error = 'Missing required property: xxx.aaa.a_properties.bbb'
        expect([schema, record]).to fail_validation_with(error)
      end

      specify 'and we are not switching on an enum field' do
        schema = {
          '$schema' => 'http://json-schema.org/draft-04/schema#',
          'type' => 'object',
          'required' => ['aaa'],
          'properties' => {
            'aaa' => {
              'type' => 'object',
              'oneOf' => [{
                'properties' => {
                  'bbb' => {
                    'type' => 'object',
                    'required' => ['ccc'],
                  }
                }
              }, {
                'properties' => {
                  'bbb' => {
                    'type' => 'object',
                    'required' => ['ddd']
                  }
                }
              }]
            }
          }
        }

        record = {'aaa' => {'bbb' => {}}}

        error = 'No match for property: aaa'
        expect([schema, record]).to fail_validation_with(error)
      end
    end

    specify 'when top-level property too short' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'minLength' => 2}
        }
      }
      record = {'aaa' => 'x'}

      error = 'Property too short: aaa (must be at least 2 characters)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when nested property too short' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {
            'type' => 'object',
            'properties' => {
              'bbb' => {'minLength' => 2}
            }
          }
        }
      }
      record = {'aaa' => {'bbb' => 'x'}}

      error = 'Property too short: aaa.bbb (must be at least 2 characters)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when property too long' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'maxLength' => 2}
        }
      }
      record = {'aaa' => 'xxx'}

      error = 'Property too long: aaa (must be at most 2 characters)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when property of wrong type and many types allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => ['number', 'string']}
        }
      }
      record = {'aaa' => ['xxx']}

      error = 'Property of wrong type: aaa (must be of type number, string)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when property of wrong type and single type allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'number'}
        }
      }
      record = {'aaa' => 'xxx'}

      error = 'Property of wrong type: aaa (must be of type number)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when property not in enum and many values allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'enum' => ['a', 'b', 'c']}
        }
      }
      record = {'aaa' => 'z'}

      error = 'Property not an allowed value: aaa (must be one of a, b, c)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when property not in enum and single value allowed' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'enum' => ['a']}
        }
      }
      record = {'aaa' => 'z'}

      error = 'Property must have value a: aaa'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when date property of wrong format' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'string', 'format' => 'date'}
        }
      }
      record = {'aaa' => 'zzz'}

      error = 'Property not of expected format: aaa (must be of format yyyy-mm-dd)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when date property is empty' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'string', 'format' => 'date'}
        }
      }
      record = {'aaa' => ''}

      error = 'Property not of expected format: aaa (must be of format yyyy-mm-dd)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when date property has a timestamp' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'string', 'format' => 'date'}
        }
      }
      record = {'aaa' => '2016-01-12T21:52:11Z'}

      expect([schema, record]).to be_valid
    end

    specify 'when date property has a timestamp and a bad date' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'string', 'format' => 'date'}
        }
      }
      dates = ["2016-03-13",
"2016-03-21",
"2016-03-12T14:58:51.941787",
"2016-03-15",
"2016-03-12T15:01:27.767907",
"2016-03-12T13:28:59.947478",
"2016-03-12T11:30:18.731536",
"2016-03-13",
"2016-03-13",
"2016-03-12T11:17:52.814474",
"2016-03-12T15:12:46.227805",
"2016-03-12T15:45:03.405024",
"2016-03-12T13:17:15.362714",
"2016-03-15",
"2016-03-13",
"2016-03-23",
"2016-03-12T08:20:02.088387",
"2016-03-21",
"2016-03-13",
"2016-03-21",
"2016-03-11T17:54:20.247649",
"2016-03-12",
"2016-03-12T15:07:20.572849",
"2016-03-20",
"2016-03-13",
"2016-03-12T11:24:07.573208",
"2016-03-20",
"2016-03-11T17:31:38.482306",
"2016-03-16",
"2016-03-12T15:15:13.430171",
"2016-03-11T17:07:26.781185",
"2016-03-12T13:33:24.754198",
"2016-03-15",
"2016-03-20",
"2016-03-12",
"2016-03-15",
"2016-03-12T14:04:36.597795",
"2016-03-24",
"2016-03-11T13:20:40.231104",
"2016-03-16",
"2016-03-20",
"2016-03-12",
"2016-03-23",
"2016-03-15",
"2016-03-24",
"2016-03-24",
"2016-03-23",
"2015-10-02 10:15:56 +0000",
"2015-02-28 17:32:37 +0000",
"2016-03-18 10:35:30 +0000",
"2016-03-07 09:48:23 +0000",
"2016-03-10 12:27:33 +0000",
"2015-02-28 18:04:19 +0000",
"2015-03-04 18:14:14 +0000",
"2015-03-09 10:44:52 +0000",
"2015-04-29 17:49:37 +0000",
"2015-09-04 13:35:52 +0000",
"2016-03-10 09:39:21 +0000",
"2016-03-11 12:28:38 +0000",
"2016-03-11 10:37:50 +0000",
"2015-09-18 11:48:50 +0000"]
      dates.each do |d|
        puts d
        record = {'aaa' => d}

        expect([schema, record]).to be_valid
      end
    end

    specify 'when non-blank property of wrong format' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'type' => 'string', 'format' => 'non-blank'}
        }
      }
      record = {'aaa' => '   '}

      error = 'Property not of expected format: aaa (must not be blank)'
      expect([schema, record]).to fail_validation_with(error)
    end

    context 'when schema includes $ref' do
      specify 'when data is valid' do
        schema_path = 'spec/schemas/aaa.json'
        record = {'aaa' => 1, 'bbb' => {'BBB' => 10}}
        expect([schema_path, record]).to be_valid
      end

      specify 'when data is invalid' do
        schema_path = 'spec/schemas/aaa.json'
        record = {'aaa' => 1, 'bbb' => {'BBB' => '10'}}
        error = 'Property of wrong type: bbb.BBB (must be of type number)'
        expect([schema_path, record]).to fail_validation_with(error)
      end
    end

    context 'when schema includes nested $refs' do
      specify 'when data is valid' do
        schema_path = 'spec/schemas/fff.json'
        record = {'fff' => {'ggg' => {'hhh' => 123}}}
        expect([schema_path, record]).to be_valid
      end

      specify 'when data is invalid' do
        schema_path = 'spec/schemas/fff.json'
        record = {'fff' => {'ggg' => {'hhh' => '123'}}}
        error = 'Property of wrong type: fff.ggg.hhh (must be of type number)'
        expect([schema_path, record]).to fail_validation_with(error)
      end

      context 'and schema is an included schema' do
        specify 'when data is valid' do
          schema_path = 'spec/schemas/includes/ggg.json'
          record = {'ggg' => {'hhh' => 123}}
          expect([schema_path, record]).to be_valid
        end

        specify 'when data is invalid' do
          schema_path = 'spec/schemas/includes/ggg.json'
          record = {'ggg' => {'hhh' => '123'}}
          error = 'Property of wrong type: ggg.hhh (must be of type number)'
          expect([schema_path, record]).to fail_validation_with(error)
        end
      end

      context 'and there is a $ref to something in an outer directory' do
        specify 'when data is valid' do
          schema_path = 'spec/schemas/iii.json'
          record = {'iii' => {'jjj' => {'kkk' => 123}}}
          expect([schema_path, record]).to be_valid
        end

        specify 'when data is invalid' do
          schema_path = 'spec/schemas/iii.json'
          record = {'iii' => {'jjj' => {'kkk' => '123'}}}
          error = 'Property of wrong type: iii.jjj.kkk (must be of type number)'
          expect([schema_path, record]).to fail_validation_with(error)
        end
      end
    end

    specify 'when schema includes oneOfs which contain $refs directly' do
      schema_path = 'spec/schemas/lll.json'
      record = {
        'mmm' => []
      }
      error = 'No match for property: mmm'
      expect([schema_path, record]).to fail_validation_with(error)
    end

    specify 'when schema includes oneOfs which contain $refs indirectly' do
      schema_path = 'spec/schemas/ccc.json'
      record = {
        'ccc' => {
          'ccc_type' => 'ddd',
          'ccc_properties' => {
            'ddd' => 'not-a-number'
          }
        }
      }
      error = 'Property of wrong type: ccc.ccc_properties.ddd (must be of type number)'
      expect([schema_path, record]).to fail_validation_with(error)
    end

    specify 'when oneOf is used to dispatch on type' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {
            'oneOf' => [
              {
                'type' => 'string',
                'format' => 'date'
              },
              {
                'type' => 'integer',
                'maxLength' => 2
              }
            ]
          }
        }
      }
      record = {'aaa' => 'not-a-date'}
      error = 'Property not of expected format: aaa (must be of format yyyy-mm-dd)'
      expect([schema, record]).to fail_validation_with(error)
    end

    specify 'when oneOf is an item in an array' do
      schema = {
        'type' => 'array',
        'items' => {
          'oneOf' => [{
            'type' => 'string',
          }]
        }
      }
      record = [1]
      error = 'No match for property: 0'
      expect([schema, record]).to fail_validation_with(error)
    end
  end

  describe '.convert_dates' do
    it 'converts dates when schema has no $refs' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {
            'type' => 'string',
            'format' => 'date'
          },
          'bbb' => {
            'type' => 'array',
            'items' => {
              'type' => 'string',
              'format' => 'date'
            }
          },
          'ccc' => {
            'type' => 'object',
            'properties' => {
              'ddd' => {
                'type' => 'string',
                'format' => 'date'
              }
            }
          }
        }
      }

      record = {
        'aaa' => '2015-01-01 extra',
        'bbb' => ['2015-01-01 extra', nil],
        'ccc' => {
          'ddd' =>  '2015-01-01 extra'
        }
      }

      expect([schema, record]).to convert_dates_to({
        'aaa' => '2015-01-01',
        'bbb' => ['2015-01-01', nil],
        'ccc' => {
          'ddd' =>  '2015-01-01'
        }
      })
    end

    it 'converts dates when schema has $refs' do
      schema_path = 'spec/schemas/yyy.json'
      record = {
        'aaa' => '2015-01-01 extra',
        'bbb' => ['2015-01-01 extra', '2015-01-01 extra'],
        'ccc' => {
          'ddd' =>  '2015-01-01 extra'
        }
      }

      expect([schema_path, record]).to convert_dates_to({
        'aaa' => '2015-01-01',
        'bbb' => ['2015-01-01', '2015-01-01'],
        'ccc' => {
          'ddd' =>  '2015-01-01'
        }
      })
    end
  end
end
