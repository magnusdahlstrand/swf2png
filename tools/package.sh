#!/usr/bin/env bash

project_name=$(basename $(pwd))
filename="$project_name.air"
certname=$(ls | grep .pfx)

adt -package -storetype pkcs12 -keystore $certname bin/$filename application.xml icons bin/$project_name.swf

if [[ $? = 0 ]]; then
	echo 'Air app created.'
else
	echo 'Error packaging app.'
fi
