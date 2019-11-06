#!/bin/bash - 
set -o nounset                             
#------------------------------------------------------------------------------
# Измените переменную среды в зависимости от провайдера:
# aws Amazon Web Services
# azure Microsoft Azure
# digitalocean  Digital Ocean
# gcp Google Cloud Platform
# yandex Yandex.cloud
#------------------------------------------------------------------------------
CLOUD=gcp
export CLOUD
cd infra/terraform-kubernetes/GCP/gcp/
terraform init && terraform apply -auto-approve
cd ../gcp_dns
terraform init && terraform apply -auto-approve
cd ../../../../
helm install --name nats k8s/charts/nats/
helm install --name kamailio k8s/charts/kamailio/
helm install --name asterisk k8s/charts/asterisk/
cd asteriskconfig
zip -r ../asterisk-config.zip *
cd ../
kubectl -n voip create secret generic asterisk-config --from-file=asterisk-config.zip




