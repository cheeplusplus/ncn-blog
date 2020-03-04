#!/bin/bash

pipenv run sssg -d --files-as-dirs -i "*.json,*.scss" src build
pipenv run pysassc src/site.scss build/site.css
