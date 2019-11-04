#!/bin/bash - 
#===============================================================================
#
#          FILE: deploy-k8s.sh
# 
#         USAGE: ./deploy-k8s.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 27.10.2019 22:12
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
#------------------------------------------------------------------------------
# Измените переменную среды в зависимости от провайдера:
# aws Amazon Web Services
# azure Microsoft Azure
# digitalocean  Digital Ocean
# gcp Google Cloud Platform
#------------------------------------------------------------------------------
CLOUD=gcp
export CLOUD
terraform -auto-approve infra/terraform-kubernetes/gcp/main.tf
kubectl apply -f k8s/00-namespace.yaml && kubectl apply -f k8s/00-rbac.yaml && kubectl apply -f k8s/01-nats.yaml &&\
kubectl apply -f k8s/02-kamailio.yaml && kubectl apply -f k8s/03-asterisk.yaml && kubectl apply -f k8s/app.yaml &&\
kubectl apply -f k8s/audiosocket.yaml && kubectl apply -f k8s/voice-service.yaml

cd asteriskconfig
zip -r ../asterisk-config.zip *
cd ../
kubectl -n voip create secret generic asterisk-config --from-file=asterisk-config.zip




