#!/usr/bin/env bash

if [[ ! -d bin ]]; then
	mkdir bin
fi

project_name=$(basename $(pwd))

mxmlc \
-library-path /usr/local/Cellar/flex_sdk/4.6.0.23201/libexec/frameworks/libs \
-library-path /usr/local/Cellar/adobe-air-sdk/3.5/libexec/frameworks/libs/air \
-show-actionscript-warnings -show-binding-warnings \
-static-link-runtime-shared-libraries \
-output bin/$project_name.swf -- src/$project_name.as
