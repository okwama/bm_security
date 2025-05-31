#!/bin/bash

# Find all .dart files and replace 'package:securexresidence/' with 'package:bm_security/'
find . -type f -name "*.dart" -exec sed -i '' 's/package:securexresidence\//package:bm_security\//g' {} +

echo "Import paths have been updated from 'securexresidence' to 'bm_security'" 