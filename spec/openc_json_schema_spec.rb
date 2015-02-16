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

      expect([schema, record]).to fail_validation_with(
        :type => :missing,
        :path => 'aaa'
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :missing,
        :path => 'aaa.bbb'
      )
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

        expect([schema, record]).to fail_validation_with(
          :type => :missing,
          :path => 'aaa.a_properties.bbb'
        )
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

        expect([schema, record]).to fail_validation_with(
          :type => :missing,
          :path => 'xxx.aaa.a_properties.bbb'
        )
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

        expect([schema, record]).to fail_validation_with(
          :type => :one_of_no_matches,
          :path => 'aaa'
        )
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

      expect([schema, record]).to fail_validation_with(
        :type => :too_short,
        :path => 'aaa',
        :length => 2
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :too_short,
        :path => 'aaa.bbb',
        :length => 2
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :too_long,
        :path => 'aaa',
        :length => 2
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :type_mismatch,
        :path => 'aaa',
        :allowed_types => ['number', 'string']
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :type_mismatch,
        :path => 'aaa',
        :allowed_types => ['number']
      )
    end

    specify 'when property not in enum' do
      schema = {
        '$schema' => 'http://json-schema.org/draft-04/schema#',
        'type' => 'object',
        'properties' => {
          'aaa' => {'enum' => ['a', 'b', 'c']}
        }
      }
      record = {'aaa' => 'z'}

      expect([schema, record]).to fail_validation_with(
        :type => :enum_mismatch,
        :path => 'aaa',
        :allowed_values => ['a', 'b', 'c']
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :extra_properties,
        :path => '',
        :extra_properties => ['bbb', 'ccc']
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :format_mismatch,
        :path => 'aaa',
        :expected_format => 'yyyy-mm-dd'
      )
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

      expect([schema, record]).to fail_validation_with(
        :type => :format_mismatch,
        :path => 'aaa',
        :expected_format => 'yyyy-mm-dd'
      )
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
        expect([schema_path, record]).to fail_validation_with(
          :type => :type_mismatch,
          :path => 'bbb.BBB',
          :allowed_types => ['number']
        )
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
        expect([schema_path, record]).to fail_validation_with(
          :type => :type_mismatch,
          :path => 'fff.ggg.hhh',
          :allowed_types => ['number']
        )
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
          expect([schema_path, record]).to fail_validation_with(
            :type => :type_mismatch,
            :path => 'ggg.hhh',
            :allowed_types => ['number']
          )
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
          expect([schema_path, record]).to fail_validation_with(
            :type => :type_mismatch,
            :path => 'iii.jjj.kkk',
            :allowed_types => ['number']
          )
        end
      end
    end

    specify 'when schema includes oneOfs which contain $refs directly' do
      schema_path = 'spec/schemas/lll.json'
      record = {
        'mmm' => []
      }
      expect([schema_path, record]).to fail_validation_with(
        :type => :one_of_no_matches,
        :path => 'mmm'
      )
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
      expect([schema_path, record]).to fail_validation_with(
        :type => :type_mismatch,
        :path => 'ccc.ccc_properties.ddd',
        :allowed_types => ['number'],
      )
    end

    specify '' do
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
      expect([schema, record]).to fail_validation_with(
        :type => :format_mismatch,
        :path => 'aaa',
        :expected_format => 'yyyy-mm-dd'
      )
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
