# Openc::JsonSchema

[![Gem Version](https://badge.fury.io/rb/openc-json_schema.svg)](https://badge.fury.io/rb/openc-json_schema)
[![Build Status](https://secure.travis-ci.org/openc/openc-json_schema.png)](https://travis-ci.org/openc/openc-json_schema)
[![Dependency Status](https://gemnasium.com/openc/openc-json_schema.png)](https://gemnasium.com/openc/openc-json_schema)
[![Coverage Status](https://coveralls.io/repos/openc/openc-json_schema/badge.png)](https://coveralls.io/r/openc/openc-json_schema)
[![Code Climate](https://codeclimate.com/github/openc/openc-json_schema.png)](https://codeclimate.com/github/openc/openc-json_schema)

A wrapper around the json-schema gem to provide better error messages on
validation failure.

## Releasing a new version

Bump the version in `lib/openc/json_schema/version.rb` according to the [Semantic Versioning](http://semver.org/) convention, then:

    git commit lib/openc/json_schema/version.rb -m 'Release new version'
    rake release # requires Rubygems credentials
