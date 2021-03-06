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

In [morph](https://github.com/sebbacon/morph), run:

    bundle update openc-json_schema
    git commit Gemfile.lock -m 'Bump openc-json_schema' && git push

Bear in mind that a morph deploy doesn't restart the resque workers;
you'll need to do this explicitly with:

    cap production resque:restart

Finally, [rebuild the Docker image](https://github.com/openc/morph-docker-ruby#readme) and deploy [morph](https://github.com/sebbacon/morph).
