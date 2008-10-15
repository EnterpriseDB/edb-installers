#!/bin/bash

$1/bin/pg_config --version | cut -f2 -d " " | cut -f1,2 -d "."
