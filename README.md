### otus-devops-project
## Asterisk on Kubernetes
## Описание проекта
#### Этот репозиторий содержит код для развертывания масштабируемого голосового приложения и инфраструктуры в Kubernetes с использованием Kamailio, Asterisk и NATS.
  ###### Настроен мониторинг с помощью Prometheus, метрики визаулизированы с помощью grafana. Автоматизирован процесс поднятия инфраструктуры с помощью terraform.

## Основные компоненты проекта
 | Сервис                                             | Адрес                                     |
 | -------------------------------------------------- | ----------------------------------------- |
 | Go библиотека интерфейса ARI Asterisk              | http://github.com/atsip76/ari             |
 | Прокси для интерфейса REST Asterisk (ARI)          | http://github.com/atsip76/ari-proxy       |
 | Netdiscover инструмент поиска в cloud networking   | http://github.com/atsip76/netdiscover     |
 | Конфиги Asterisk  шаблоны kubernetes-based         | http://github.com/atsip76/asterisk-config |
 | Kamailio диспетчер kubernetes-based                | http://github.com/atsip76/dispatchers     |
 | AudioSocket                                        | http://github.com/atsip76/audiosocket     |

## Подготовка инфраструктуры с использованием trerraform
* Terraform v.012

Предусмотренны два варианта разворачивания k8s, с использованием утилиты kubergrunt https://www.gruntwork.io/ и более простой вариант без использования доп. утилит. Вариант с кубергрантом не требует предварительных рукопашных действий в консоли gcp по созданию и сохранению локально credentionals, содержит расширенный набор параметров и более гибкий подход в создании кластера как приватного так и паблик. 
##### Вариант с использованием kubergrunt:
В этом варианте используется форк модуля Terraform от https://www.gruntwork.io/ для запуска кластера Kubernetes на Google Cloud Platform (GCP) с Helm и Tiller.
Используем утилиту kubergrunt для безопасного управления парами ключей сертификатов TLS, которые используются Tiller.
Ваша система должна быть настроена так, чтобы она могла находить `terraform`,` gcloud`, `kubectl`,`kubergrunt`, и `helm` утилиты в переменной `PATH`. 
Руководства по установке необходимых утилит:

1. [`gcloud`] (https://cloud.google.com/sdk/gcloud/)
2. [`kubectl`] (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
3. [`terraform`] (https://learn.hashicorp.com/terraform/getting-started/install.html)
4. [`helm`] (https://docs.helm.sh/using_helm/#install-helm)
5. [`kubergrunt`] (https://github.com/gruntwork-io/kubergrunt/releases) (минимальная версия: v0.3.8)

* kubergrunt используется для сокрытия секретов передаваемых в стейт файле terraform.

###### Подготовка:
* Создайте новый проект используя консоль GCP
* Активируйте Compute Engine API - APIs & Services - Add credentials to your project
* Внесите необходимые изменения в переменные файла terraform.tfvars

###### Поднимаем инфраструктуру проекта:

```sh
cd infra/terraform-kubernetes/gcp-kubergrunt/
terraform init
terraform apply
```

##### Вариант без kubergrunt:
* Создаем ключ сервисного аккаунта gcp json format (APIs & Services-> Credentials-> Create credentials{Create service account key}) и сохраняем локально ~/.config/GCP/key-id-project.json

Руководства по установке необходимых утилит:
1. [`gcloud`] (https://cloud.google.com/sdk/gcloud/)
2. [`kubectl`] (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
3. [`terraform`] (https://learn.hashicorp.com/terraform/getting-started/install.html)
4. [`helm`] (https://docs.helm.sh/using_helm/#install-helm)

###### Поднимаем инфраструктуру проекта:
```sh
cd infra/terraform-kubernetes/gcp/
#редактируем terraform.tfvars
terraform init
terraform apply
```
###### Ставим tiller если вариант без kubergrunt:
```sh
cd infra/terraform-kubernetes/tiller
kubectl apply -f tiller.yml
helm init --service-account tiller
```
###### Устанавливаем GitLab
```sh
cd k8s/charts/
helm repo add gitlab https://charts.gitlab.io
helm fetch gitlab/gitlab-omnibus --version 0.1.37 --untar
helm install --name gitlab . -f values.yaml
```

###### Создаем A записи сервисов в DNS
* Регестрируем имя своего домена Cloud [`DNS`](https://console.cloud.google.com/net-services/dns/zones?project=test-otus&folder&organizationId)
```sh
cd infra/terraform-kubernetes/gcp_dns
#редактируем terraform.tfvars используем свои данные
terraform init
terraform apply
```





### Конфигурация Asterisk
Требуемая конфигурация для Asterisk была значительно сокращена, но миниму необходимо настроить: dialplan и pjsip.
Примеры включены в каталог asteriskconfig, в директории extensions.d & pjsip.d.
Вам потребуется обновить файл inbound.conf.tmpl, указав свои DID (номера телефонов).
Или добавить свои конфигурационные файлы транков и экстеншенов.
Заархивируйте эти файлы конфигурации в файл asterisk-config.zip:
```sh
zip -r asterisk-config.zip *
```
Затем сохраните файл asterisk-config.zip в kubernetes как секрет с именем «asterisk-config»:
```sh
kubectl create secret generic asterisk-config --from-file=asterisk-config.zip
```
##### Рзворачивание сервисов приложений 
```sh
/deploy-k8s.sh
```