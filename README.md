### otus-devops-project
## Asterisk on Kubernetes
## Описание проекта
#### Этот репозиторий содержит код для развертывания масштабируемого голосового приложения и инфраструктуры в Kubernetes с использованием Kamailio, Asterisk и NATS.
#### Настроен мониторинг с помощью Prometheus, метрики визаулизированы с помощью grafana. Автоматизирован процесс поднятия инфраструктуры с помощью packer, terraform, ansible.

## Основные компоненты проекта
 | Сервис                                             | Адрес                              |
 | -------------------------------------------------- |  ---------------------------------- |
 | Go библиотека интерфейса ARI Asterisk              | http://github.com/atsip76/ari             |
 | Прокси для интерфейса REST Asterisk (ARI)          | http://github.com/CyCoreSystems/ari-proxy |
 | Netdiscover инструмент поиска в cloud networking   | http://github.com/atsip76/netdiscover     |
 | Asterisk конфиги kubernetes-based Asterisk шаблоны | http://github.com/atsip76/asterisk-config |
 | Kamailio диспетчер kubernetes-based                | http://github.com/atsip76/dispatchers     |
 | AudioSocket                                        | http://github.com/atsip76/audiosocket     |

## Подготовка инфраструктуры с использованием trerraform
