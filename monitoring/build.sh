#!/bin/bash - 
#===============================================================================
#
#          FILE: build.sh
# 
#         USAGE: ./build.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 26.08.2019 22:31
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

docker build -t atsip/cloudprober ./cloudprober
docker build -t atsip/blackbox-exporter ./blackbox-exporter
docker build -t atsip/prometheus ./prometheus

