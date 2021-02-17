#!/bin/bash
export RAILS_SERVE_STATIC_FILES=true
nohup rails s -b 167.71.176.223 --port 8080 -e production &
