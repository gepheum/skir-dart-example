#!/bin/bash

set -e

npm i
npm run install-dart-deps
npm run build
npm run run:snippets
npm run run:reflection
