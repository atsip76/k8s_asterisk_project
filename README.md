### otus-devops-project
## Asterisk on Kubernetes
## Описание проекта
#### Этот репозиторий содержит код для развертывания масштабируемого голосового приложения и инфраструктуры в Kubernetes с использованием Kamailio, Asterisk и NATS.
#### Настроен мониторинг с помощью Prometheus, метрики визаулизированы с помощью grafana. Автоматизирован процесс поднятия инфраструктуры с помощью packer, terraform, ansible.

## Основные компоненты проекта
 | Сервис                                             | Адрес                                     |
 | -------------------------------------------------- | ----------------------------------------- |
 | Go библиотека интерфейса ARI Asterisk              | http://github.com/atsip76/ari             |
 | Прокси для интерфейса REST Asterisk (ARI)          | http://github.com/atsip76/ari-proxy       |
 | Netdiscover инструмент поиска в cloud networking   | http://github.com/atsip76/netdiscover     |
 | Конфиги Asterisk  шаблоны kubernetes-based         | http://github.com/atsip76/asterisk-config 
 |
 | Kamailio диспетчер kubernetes-based                | http://github.com/atsip76/dispatchers     |
 | AudioSocket                                        | http://github.com/atsip76/audiosocket     |

## Подготовка инфраструктуры с использованием trerraform
* Terraform v.012
  
Создаем ключ сервисного аккаунта gcp json format (APIs & Services-> Credentials-> Create credentials{Create service account key}) и сохраняем локально ~/.config/GCP/key-id-project.json

Поднимаем инфраструктуру проекта:

```sh
cd infra/terraform-kubernetes/cluster/
terraform init
terraform apply
```

## Конфигурация Asterisk
Требуемая конфигурация для Asterisk была значительно сокращена, но необходимо настроить: ARI, dialplan и PJSIP. Примеры включены в каталог asteriskconfig . Вам потребуется обновить файл inbound.conf.tmpl, указав свои DID (номера телефонов). Или добавить свои конфигурационные файлы.
Теперь заархивируйте эти файлы конфигурации в файл asterisk-config.zip:
```sh
zip -r asterisk-config.zip *
```
Затем сохраните файл asterisk-config.zip в kubernetes как секрет с именем «asterisk-config»:
```sh
kubectl create secret generic asterisk-config --from-file=asterisk-config.zip
```
