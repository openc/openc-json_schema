#!/bin/bash

gem build openc-json_schema.gemspec
gem push $(ls *gem|tail -1)

function clean {
rm *gem
}
trap clean EXIT
