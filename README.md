# Описание курсовой работы версии 1.0.0

## Репозиторий
https://github.com/hfrog/otus-k8s

## Среда
Yandex Cloud

## ОС и Kubernetes
ОС Ubuntu 20.04<br>
Kubernetes 1.28

## Архитектура
Виртуальные машины устанавливает Terraform.
Кластер Kubenetes устанавливается скриптами с помощью [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/). Доступ к API реализован через haproxy с балансировкой нагрузки на мастеры.

CNI - [Cilium](https://cilium.io). Планировал настроить BGP, но облако не пропускает трафик для сетей, отличных от сети виртуалок.
Единственный вариант - статический маршрут в облаке, так я смаршрутизировал сеть LoadBalancer на мастер, чтобы ingress был доступен с haproxy.

CSI - [csi-s3](https://cloud.yandex.ru/ru/marketplace/products/yc/csi-s3) с хранением данных в [Yandex Object Storage](https://cloud.yandex.ru/ru/docs/storage/).

Для маршрутизации HTTP/HTTPS используется [ingress-nginx](https://github.com/kubernetes/ingress-nginx), для автоматического получения сертификатов - [cert-manager](https://cert-manager.io), staging чтобы не превышать лимиты при отладке.

Для сбора, хранения и отображения метрик используется стек [Prometheus+Grafana](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md),
а для логов - [Loki](https://grafana.com/oss/loki/)+[Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/), отображение также Grafana.

Для демонстрации работоспособности системы используется [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo/tree/main),
тестовый сайт доступен по адресу https://msd-dev.51.250.96.180.hfrog.ru

Приложение деплоится с помощью [werf](https://werf.io).

Для хранения образов используется [Yandex Container Registry](https://cloud.yandex.ru/ru/docs/container-registry/).

Система не требует ручной донастройки и готова к работе сразу же по окончании работы установочных задач.

## CI/CD
GitHub Actions<br>
Настроены три workflow:
- terraform
- k8s-cluster
- app

Workflows запускаются руками.

Все секретные ключи, пароли, идентификаторы хранятся в секретах GitHub и не видны в выводе GitHub Actions.

Для передачи динамической информации между задачами в GitHub Actions, например адресов ВМ и конфига kubectl, используется Yandex Object Storage.

## Terraform
- Хранит состояние в Yandex Object Storage
- Настраивает статический маршрут для сети сервисов типа LoadBalancer на адрес мастера
- Кол-во мастеров и воркеров задаётся переменными, скрипты установки умеют добавлять в кластер Kubernetes тех и других
- Доступ снаружи ограничен портами 22, 80, 443, 6443

## Кластер Kubernetes
Первый мастер устанавливается с помощью `kubeadm init`.

Остальные мастера и воркеры добавляются в кластер командами соответственно `kubeadm join --control-plane` либо `kubeadm join`.

Токены и другая информация, необходимая для подключения, вычисляется автоматически.

## Haproxy
Терраформом зарезервирован для ВМ c haproxy статический адрес, который не меняется при остановке ВМ.

Haproxy настраивается скриптами в зависимости от адресов ВМ и сети LoadBalancer.

## Grafana
Grafana доступна снаружи по адресу https://grafana.51.250.96.180.hfrog.ru, пароль у меня.<br>
Доски для ingress-nginx и логов создаются автоматически через ConfigMap, а для Kubernetes, Cilium, Loki, Prometeus включены встроенные доски.

## Werf
Созданы зависимые чарты по всем микросервисам, импортированы исходники образов. Werf собирает все образы и деплоит приложение одним запуском `werf converge`.

Микросервис `loadgenerator` для запуска требует `frontend`. Для того, чтоб он запускался без ошибок, ему средствами werf понижен приоритет деплоя.

## Время развёртывания
Время развёртывания от начала до конца - 20 минут

## Планы
- перейти на Ubuntu 22.04 и Kubernetes 1.29
- переделать скрипты на Ansible
- попробовать Deckhouse
