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

    specify 'when property of wrong format' do
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

    specify 'when property with format is empty' do
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
        'bbb' => ['2015-01-01 extra', '2015-01-01 extra'],
        'ccc' => {
          'ddd' =>  '2015-01-01 extra'
        }
      }

      expect([schema, record]).to convert_dates_to({
        'aaa' => '2015-01-01',
        'bbb' => ['2015-01-01', '2015-01-01'],
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
