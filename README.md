# itokareva_platform
itokareva Platform repository
<details>
  <summary>## Домашняя работа 1</summary>

  ## Настройка локального Настройка локального окружения. Запуск окружения. 
  ## Запуск первого контейнера. первого контейнера. Работа с kubectl 

1) Установлен minikube и запущена виртуальная машина с кластером Kubernetes
2) Создан Dockerﬁle:

   - Запускающий web-сервер на порту 8000 
   - Отдающий содержимое директории /app внутри контейнера
     (например, если в директории /app лежит файл homework.html, то при запуске контейнера данный файл должен быть доступен 
      по URL http://localhost:8000/homework.html)
3) Построен образ контейнера и размещен в публичном Container Registry: itokareva/web:1.0
4) Создан манифест web-pod.yaml для создания pod web c меткой app со значением web, содержащего один контейнер с названием web
5) Добавлен init-контейнер, генерирующий страницу index.html во внутрь пода web
6) Выполнен port-forward и проверена работа приложения
7) Знакомство с приложеним Hipster Shop. Микросервис frontend склонирован, построен образ itokareva/hipster-frontend:1.0 
   и размещен на Docker Hub 
8) Использован ad-hoc режим для генерации манифеста frontend-pod.yaml

   Задание со (*)
9) Выяснена причина, по которой pod frontend находится в статусе Error: не объявлены переменные среды. 
   Исправлено в манифесте frontend-pod-healthy.yaml.  pod frontend - находится в статусе Running.

10)   
   Задание: Разберитесь почему все pod в namespace kube-system восстановились после удаления. 

   core-dns - восстанавливается, потому что kubernetes works in a declarative manner, which means we declare what the desired state should 
   be and kubernetes manages it for us. Control-manager is the component which is responsible for keeping track and maintaining the 
   required state by interacting with api-server and various controllers. So, it can also be treated as the interacting medium between 
   various controllers and api-server.
   
   kube-apiserver - желаемое состояние хранится в etcd. В локальном кластере используются статические поды.
   Полная информация здесь: https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/

   В миникубе за всеми подами из plain panale присматривает kubelet. Заходим в VM minikube ssh и смотрим.
   Сам kubelet запускается, как deamon.
   ● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; disabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Wed 2020-12-16 16:53:07 UTC; 36min ago
     Docs: http://kubernetes.io/docs/
 Main PID: 2828 (kubelet)
    Tasks: 21 (limit: 2363)
   Memory: 113.9M
   CGroup: /system.slice/kubelet.service
           └─2828 /var/lib/minikube/binaries/v1.19.2/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime=docker --hostname-override=minikube --kubeconfig=/etc/kubernetes/kubelet.conf --node-ip=192.168.99.100


   В конфиг-файле kubelet /etc/kubernetes/kubelet.conf прописан путь:

   staticPodPath: /etc/kubernetes/manifests   
 
   Здесь лежат статичиские yaml-файлы, которые kubelet использует для рестарта etcd, kube-apiserver, kube-controller-manager, kube-scheduler: 

   $ ls /etc/kubernetes/manifests/
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml

   Сам kubelet рестартует VM.

</details>

<details>
  <summary>## Домашняя работа 2</summary>

  ## Kubernetes controllers. Kubernetes controllers. ReplicaSet, Deployment, ReplicaSet, Deployment, DaemonSet 

1) Установлен kind и развернут k8s кластер по шаблону:

kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes: 
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker   

2) ReplicaSet
   Почему обновление версии ReplicaSet не повлекло обновление запущенных pod?
   - потому что количество реплик было ограничено до 3, а мы выполнили apply  и это был бы уже 4-ый под
3) Deployment
3.1)
   - выкатка версии по default стратегии Update:
   
     - Создание одного нового pod с версией образа v2.0
     - Удаление одного из старых pod 
     - Создание еще одного нового pod

kubectl get replicaset  paymentservice-778bddd87 -o=jsonpath='{.spec.template.spec.containers[0].image}'
itokareva/hipster-paymentservice:2.0
kubectl get replicaset paymentservice-7d457979f8 -o=jsonpath='{.spec.template.spec.containers[0].image}'
itokareva/hipster-paymentservice:1.0
kubectl get pods -l app=paymentservice -o=jsonpath='{.items[0:3].spec.containers[0].image}'
itokareva/hipster-paymentservice:2.0 itokareva/hipster-paymentservice:2.0 itokareva/hipster-paymentservice:2.0
3.2) 
   - выкатка версии по стпатегии blue-green
     - Развертывание трех новых pod 
     - Удаление трех старых pod
3.3)
   - выкатка вырсии по стратегии Reverse Rolling Update 
     - Удаление одного старого pod 
     - Создание одного нового pod 
4) Примен манифест с frontend-deployment.yaml readinessProbe и с версией itokareva/hipster-frontend:1.0. В описании контейнера видим:

   Containers:
  server:
    Container ID:   containerd://e153d21784690868614dcafe819242e26be939edf169e05299075aa5cc29c2bf
    Image:          itokareva/hipster-frontend:1.0
    Image ID:       docker.io/itokareva/hipster-frontend@sha256:ffa410a06cc23df8b2dc84f983e8ed1ff22a7b73a8fdb2acaf27aeb31057c94e
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 10 Dec 2020 22:22:17 +0300
    Ready:          False
    Restart Count:  0
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3

5) Выкатили itokareva/hipster-frontend:2.0 с ошибочным path: http://10.244.5.12:8080/_health. Выкатка не пошла, потому что
   проверка Readiness не прошла.

Warning  Unhealthy  9s (x7 over 69s)  kubelet, kind-worker2  Readiness probe failed: Get http://10.244.5.12:8080/_health: dial tcp 10.244.5.12:8080: connect: connection refused

6) Deamonset

6.1) Применен манифест node-exporter-daemonset-work.yaml - экспортеры развернут только на worker-nodes

NAME                  READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
node-exporter-8hrm5   1/1     Running   0          27s   10.244.3.7   kind-worker    <none>           <none>
node-exporter-dq2sx   1/1     Running   0          27s   10.244.4.7   kind-worker3   <none>           <none>
node-exporter-wldhx   1/1     Running   0          27s   10.244.5.7   kind-worker2   <none>           <none>

6.2) Применен манифест node-exporter-daemonset.yaml c tolerations - экспортеры развернуты как на мастер, так и worker-нодах.

   На worker2:

Events:
  Type    Reason     Age    From                   Message
  ----    ------     ----   ----                   -------
  Normal  Scheduled  8m53s  default-scheduler      Successfully assigned default/node-exporter-6qscr to kind-worker2
  Normal  Pulling    8m51s  kubelet, kind-worker2  Pulling image "quay.io/prometheus/node-exporter:v1.0.1"
  Normal  Pulled     8m8s   kubelet, kind-worker2  Successfully pulled image "quay.io/prometheus/node-exporter:v1.0.1"
  Normal  Created    8m2s   kubelet, kind-worker2  Created container node-exporter
  Normal  Started    8m     kubelet, kind-worker2  Started container node-exporter
  Normal  Pulling    8m     kubelet, kind-worker2  Pulling image "quay.io/brancz/kube-rbac-proxy:v0.8.0"
  Normal  Pulled     7m8s   kubelet, kind-worker2  Successfully pulled image "quay.io/brancz/kube-rbac-proxy:v0.8.0"
  Normal  Created    7m6s   kubelet, kind-worker2  Created container kube-rbac-proxy
  Normal  Started    7m4s   kubelet, kind-worker2  Started container kube-rbac-proxy

   На мастере (control-plane2):

Events:
  Type    Reason     Age    From                          Message
  ----    ------     ----   ----                          -------
  Normal  Scheduled  7m23s  default-scheduler             Successfully assigned default/node-exporter-42q8r to kind-control-plane2
  Normal  Pulling    7m21s  kubelet, kind-control-plane2  Pulling image "quay.io/prometheus/node-exporter:v1.0.1"
  Normal  Pulled     6m24s  kubelet, kind-control-plane2  Successfully pulled image "quay.io/prometheus/node-exporter:v1.0.1"
  Normal  Created    6m23s  kubelet, kind-control-plane2  Created container node-exporter
  Normal  Started    6m23s  kubelet, kind-control-plane2  Started container node-exporter
  Normal  Pulling    6m23s  kubelet, kind-control-plane2  Pulling image "quay.io/brancz/kube-rbac-proxy:v0.8.0"
  Normal  Pulled     5m41s  kubelet, kind-control-plane2  Successfully pulled image "quay.io/brancz/kube-rbac-proxy:v0.8.0"
  Normal  Created    5m39s  kubelet, kind-control-plane2  Created container kube-rbac-proxy
  Normal  Started    5m38s  kubelet, kind-control-plane2  Started container kube-rbac-proxy

NOTE:
 
- Tolerations are applied to pods, and allow (but do not require) the pods to schedule onto nodes with matching taints.

- There are two special cases:
  An empty key with operator Exists matches all keys, values and effects which means this will tolerate everything.

An empty effect matches all effects with key key1.

</details>

<details>
  <summary>## Домашняя работа 3</summary>

  ## Безопасность и управление доступом 

  -  Решение задач task01, task02, task03 в  .yaml-файлах в одноименных каталогах.

</details>

<details>
  <summary>## Домашняя работа 4</summary>

  ## Сетевая подсистема Kubernetes

1) Создание Service
   -  создание сервиса с типом ClusterIP 
   -  разбор цепочек правил перенаправления трафика в iptables
   -  включение IPVS для kube-proxy
   -  исследоваие конфигурации через ipvsadm:

   TCP  10.111.37.78:80 rr
  -> 172.17.0.9:8000              Masq    1      0          0
  -> 172.17.0.10:8000             Masq    1      0          0
  -> 172.17.0.11:8000             Masq    1      0          0

   Пинг к ClusterIP уже работает:
$ ping -c1 10.111.37.78
PING 10.111.37.78 (10.111.37.78): 56 data bytes
64 bytes from 10.111.37.78: seq=0 ttl=64 time=1.835 ms 
--- 10.111.37.78 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 1.835/1.835/1.835 ms
   	 
2) Установка MetalLB в Layer2-режиме 
  
   - установка MetalLB
   - настройка балансировщика с помощью ConfigMap
   - посмотр логов пода-контроллера MetalLB, чтобы увидеть как назначаются ip-адреса балансировщикам:

{"caller":"service.go:114","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2020-12-17T19:49:48.676538589Z"}


Name:                     web-svc-lb
Namespace:                default
Labels:                   <none>
Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"web-svc-lb","namespace":"default"},"spec":{"ports":[{"port":80,"p...
Selector:                 app=web
Type:                     LoadBalancer
IP:                       10.101.95.125
LoadBalancer Ingress:     172.17.255.1
Port:                     <unset>  80/TCP
TargetPort:               8000/TCP
NodePort:                 <unset>  30388/TCP
Endpoints:                172.17.0.10:8000,172.17.0.11:8000,172.17.0.9:8000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason        Age    From                Message
  ----    ------        ----   ----                -------
  Normal  IPAllocated   8m17s  metallb-controller  Assigned IP "172.17.255.1"
  Normal  nodeAssigned  8m16s  metallb-speaker     announcing from node "minikube"

   - проверка конфигурации:
     
     -  пробрасываем маршрут:
        sudo ip route add 172.17.255.0/24 via 192.168.99.100 
     - проверяем, что ссылка работает в браузере или через curl:
        sudo ip route add 172.17.255.0/24 via 192.168.99.100 +
        curl http://172.17.255.1/index.html

   Задание со (*)

   Создан сервис LoadBalancer , который открывает доступ к CoreDNS снаружи кластера (позволяет получать записи через внешний IP).
   Сервис работает по протоколам TCP и UDP на одно ip-адресе балансировщика.
   Использована аннотация: metallb.universe.tf/allow-shared-ip

   kubectl get svc -n kube-system
NAME             TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                  AGE
kube-dns         ClusterIP      10.96.0.10       <none>         53/UDP,53/TCP,9153/TCP   88d
metrics-server   ClusterIP      10.100.207.229   <none>         443/TCP                  86d
svc-tcp          LoadBalancer   10.100.116.106   172.17.255.3   53:31902/TCP             21m
svc-udp          LoadBalancer   10.111.239.29    172.17.255.3   53:32341/UDP             21m

nslookup 172.17.0.25  172.17.255.3
25.0.17.172.in-addr.arpa        name = 172-17-0-25.web-svc2.default.svc.cluster.local.

default.svc.cluster.local svc.cluster.local cluster.local


nslookup web-svc2.default.svc.cluster.local  172.17.255.3
Server:         172.17.255.3
Address:        172.17.255.3#53

Name:   web-svc2.default.svc.cluster.local
Address: 172.17.0.23
Name:   web-svc2.default.svc.cluster.local
Address: 172.17.0.24
Name:   web-svc2.default.svc.cluster.local
Address: 172.17.0.25
   

3) Установка Ingress-контроллера и прокси ingress-nginx
   - установлен "коробочный" ingressnginx от проекта Kubernetes
   - Создадан файл nginx-lb.yaml c конфигурацией LoadBalancer: MetalLB выдал 172.17.255.2 сервису.
     curl 172.17.255.2
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html> 
   - Создание Headless-сервиса:
     ClusterIP для сервиса web-svc действительно не назначен 

4) Создание правил Ingress

   - настроен ingress-прокси: web-ingress.yaml

kubectl describe ingress web
Name:             web
Namespace:        default
Address:          192.168.99.100
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /web   web-svc:8000 (172.17.0.10:8000,172.17.0.11:8000,172.17.0.9:8000)
Annotations:
  nginx.ingress.kubernetes.io/rewrite-target:        /
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"networking.k8s.io/v1beta1","kind":"Ingress","metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"},"name":"web","namespace":"default"},"spec":{"rules":[{"http":{"paths":[{"backend":{"serviceName":"web-svc","servicePort":8000},"path":"/web"}]}}]}}

Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
q
q
  Normal  Sync    19s (x2 over 60s)  nginx-ingress-controller  Scheduled for sync

   - проверка, что наша страничка доступна через браузер или через curl^
curl 172.17.255.2/web/index.html
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
<pre><font color=white>0111010011111011110010000111011000001110000110010011101000001100101
011110010100111010001111101001011000001110110101110111001000110</font><br><font color=white
>100100000010001110110001011101011100101101011111100110110110010011111110110110100100111101

   Задание со (*) Ingress для Dashboard

   Добавлен доступ к kubernetes-dashboard через наш Ingress-прокси:
   сервис доступен через префикс /dashboard. 

   Задание со (*) Canary для Ingress  

   Реализовано канареечное развертывание с помощью ingress-nginx:
   часть трафика перенаправляется на выделенную группу подов по HTTP-заголовку 
   
curl http://lb-ingress.local/web/index.html
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
<pre><font color=white>011101001111101111001000011101100000111000011001
</details>

</details>

<details>
  <summary>## Домашняя работа 5</summary>

  ## Хранение данных в Kubernetes.Volumes, Storages, Statefull-приложения

В этом ДЗ мы развернем StatefulSet c MinIO  - локальным S3 хранилищем.

Задание со (*) 

В конфигурации нашего StatefulSet данные указаны в открытом виде, что не безопасно. Поместите данные в SECRETS  и настройте конфигурацию на их использование.
Созданы новые файлы minio_secret.yaml и miniostatefulset.yaml.
Запуститься под с MinIO - запустился с применением новой конфигурации.

</details>


<details>
  <summary>## Домашняя работа 6</summary>

  ## Шаблонизация манифестов. Helm и его аналоги (Jsonnet, Kustomize)

1) Подготовительные работы

-  развернут GKE кластер
-  установка Helm 3 на локальную машину

2) Работа с helm. Развернтывание сервисов: 

 - [сnginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) сервис, обеспечивающий доступ к публичным ресурсам кластера
 - [cert-manager](https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager) - сервис, позволяющий динамически генерировать Let's Encrypt сертификаты для ingress ресурсов
 - [chartmuseum](https://github.com/helm/charts/tree/master/stable/chartmuseum) - специализированный репозиторий для хранения helm charts 
 - [harbor](https://github.com/goharbor/harbor-helm) - хранилище артефактов общего назначения (Docker Registry), поддерживающее helm charts

3) Cert-manager. Самостоятельное задание. 

-  Изучите [документацию](https://docs.cert-manager.io/en/latest/) cert-manager, и определите, что еще требуется установить для корректной работы
-  Манифест дополнительно созданного ресурса clusterissuer размещена в kubernetes-templating/cert-manager/clusterissuer.yaml

4) Chartmuseum.

-  произведена кастомизированная установка chartmuseum, параметры  размещены в kubernetes-templating/chartmuseum/values.yaml
-  проверена успешность устаноки:
a) Chartmuseum доступен по URL https://chartmuseum.<IP>.nip.io 
b) Сертификат для данного URL валиден
![screen1](kubernetes-templating/chartmuseum/chartmuseum.png)

5) Задание со (*)

   * Научитесь работать с chartmuseum 
   * Опишите последовательность действий, необходимых для добавления туда helm chart's и их установки с использованием chartmuseum как репозитория

Воспользовалась [инструкцией](https://chartmuseum.com/docs/#uploading-a-chart-package)

~~~sh
cd kubernetes-templating/chartmuseum/prometheus
helm package .
curl --data-binary "@prometheus-11.12.1.tgz" https://chartmuseum.35.228.39.47.nip.io/api/charts 
helm repo add chartmuseum https://chartmuseum.35.228.39.47.nip.io
helm search repo prometheus
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
chartmuseum/prometheus                  11.12.1         2.20.1          DEPRECATED Prometheus is a monitoring system an...

helm install prometheus chartmuseum/prometheus

WARNING: This chart is deprecated
NAME: prometheus
LAST DEPLOYED: Sun Jan  3 23:58:15 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
DEPRECATED and moved to <https://github.com/prometheus-community/helm-charts>The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.default.svc.cluster.local
helm delete prometheus
~~~

6) harbor. Самостоятельное задание

*  Установите harbor в кластер с использованием helm3 Используйте репозиторий  
*  Используйте репозиторий  и CHART VERSION 1.1.2 
Требования:

*  Должен быть включен ingress и настроен host harbor.<IPадрес>.nip.io
*  Должен быть включен TLS и выписан валидный сертификат

-  Используемый файл используемый файл values.yaml размещен в директорию kubernetes-templating/harbor/
-  Проверен критерий успешности ![screen1](kubernetes-templating/harbor/harbor.png)

7) Helmfile. Задание со (*)

Опишите установку nginx-ingress, cert-manager и harbor в helmfile.
Получившиеся файлы размещены в kubernetes-templating/helmfile
Harbor установился, но не отрабатывает postsync hook для cert-manager и сайт работает но с инвалидным серификатом.
Так же не получилось передать external-ip, который назначается nginx-ingress во время его создания.


8) Создаем свой helm chart 

Используем [hipster-shop](https://github.com/GoogleCloudPlatform/microservices-demo) - демо-приложение , представляющее собой типичный набор микросервисов.

-  изначально все сервисы создаются из одного манифеста kubernetes-templating/hipster-shop/all-hipstershop.yaml 
-  вынесен микросервис frontend в директорию kubernetes-templating/frontend
-  добавленя шаблонизация values.yaml для frontend
-  добавлены зависимости для frontend для микросервисного приложения hipster-shop
-  Задание со (*)
   *  сервис Redis устанавливается, как зависимость с использованием bitnami community chart


9) Работа с helm-secrets 

-  установлен плагин helm-secrets и необходимые для него зависимости 
~~~sh
sudo rpm --install sops-3.6.1-1.x86_64.rpm
sudo dnf install gnupg2
helm plugin install https://github.com/futuresimple/helm-secrets --version 2.0.2
-----------------------
gpg --full-generate-key
sops -e -i --pgp 4993E121B5A4C5D8ECE4238F9797DC278078219B secrets.yaml
gpg --export-secret-keys >~/.gnupg/secring.gpg
cp -fs /run/user/1100/gnupg/S.gpg-agent /home/itokareva/.gnupg/
helm secrets view secrets.yaml		
~~~

-  создан файл kubernetestemplating/frontend/templates/secret.yaml
-  Теперь, если мы передадим в helm файл secrets.yaml как values файл - плагин helm-secrets поймет,
 что его надо расшифровать, а значение ключа visibleKey подставить в соответствующий шаблон секрета.

~~~sh
helm secrets upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop \
> -f kubernetes-templating/frontend/values.yaml \
> -f kubernetes-templating/frontend/secrets.yaml
Release "frontend" does not exist. Installing it now.
NAME: frontend
LAST DEPLOYED: Thu Jan  7 23:18:29 2021
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 1
TEST SUITE: None
removed 'kubernetes-templating/frontend/secrets.yaml.dec'
~~~ 
 
10) Kubecfg

Kubecfg предполагает хранение манифестов в файлах формата .jsonnet и их генерацию перед установкой. 
Общая логика работы с использованием jsonnet следующая:
* Пишем общий для сервисов , включающий описание service и deployment
* [наследуемся](https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-04/05-Templating/hipster-shop-jsonnet/payment-shipping.jsonnet) от него, указывая параметры для конкретных сервисов 

-  вынесены манифесты, описывающие service и deployment для микросервисов paymentservice и shippingservice из файла all-hipster-shop.yaml
 в директорию kubernetes-templating/kubecfg
-  установлен kubecfg
-  создан services.jsonnet
-  библиотека services.jsonnet от bitnami немного подкорректирована
-  проверка, что манифесты генерируются корректно:
~~~sh
kubecfg show services.jsonnet
~~~
-  установка манифестов:
~~~sh
kubecfg update services.jsonnet --namespace hipster-shop
~~~

11) Kustomize | Самостоятельное задание

-  отпилен микросервис cartservice от hipster-shop
-  реализована установка в окружениях dev и prod
-  результаты работы помещены в директорию kubernetestemplating/kustomize 
-  установка на окружение dev работает так:

~~~sh
kubectl apply -k kubernetes-templating/kustomize/overlays/dev
~~~

</details>

<details>
  <summary>## Домашняя работа 7</summary>

  ##Custom Resource Definitions. Operators

1) Cоздадим CustomResource mysql-instance
2) Создали CustomResourceDefinition mysqls.otus.homework
3) Добавлена валидация в спецификацию CRD

##Операторы

Оператор включает в себя CustomResourceDefinition и сustom сontroller
- CRD содержит описание объектов CR
- Контроллер следит за объектами определенного типа, и осуществляет всю логику работы оператора

4) Создаем контроллер
##Требование к созданию контроллера:

4.1) При создании объекта типа ( kind: mySQL ), он будет:
* Cоздавать PersistentVolume, PersistentVolumeClaim, Deployment, Service для mysql
* Создавать PersistentVolume, PersistentVolumeClaim для бэкапов базы данных, если их еще нет.
* Пытаться восстановиться из бэкапа
4.2) При удалении объекта типа ( kind: mySQL ), он будет:
* Cоздавать PersistentVolume, PersistentVolumeClaim, Deployment, Service для mysql
* Создавать PersistentVolume, PersistentVolumeClaim для бэкапов базы данных, если их еще нет.
* Пытаться восстановиться из бэкапа
* Удалять все успешно завершенные backup-job и restore-job
* Удалять PersistentVolume, PersistentVolumeClaim, Deployment, Service для mysql

Потребовалось выполнить следующие подготовительные работы:

~~~sh
sudo dnf install  openssl-devel bzip2-devel libffi-devel
cd /opt
sudo wget https://www.python.org/ftp/python/3.7.9/Python-3.7.9.tgz
sudo tar -xzf Python-3.7.9.tgz
sudo rm Python-3.7.9.tgz
cd Python-3.7.9/
sudo ./configure --enable-optimizations
sudo make altinstall
/usr/local/bin/python3.7 -m pip install --upgrade pip
pip3.7 install kopf
pip3.7 install kubernetes
pip3.7 install jinja2
kopf run mysql-operator.py

[2021-01-10 01:40:55,019] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2021-01-10 01:40:55,019] kopf.objects         [INFO    ] [default/mysql-instance] Creation event is processed: 1 succeeded; 0 failed.
~~~

В другом окне создаем cr mysql-instance и проверяем что deployment, service, pv и pvc создались:

~~~sh
$ kubectl apply -f deploy/crd.yaml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework unchanged
$ kubectl apply -f deploy/cr.yaml
mysql.otus.homework/mysql-instance created
$ kubectl get deployment.apps
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
mysql-instance   1/1     1            1           40s
$ kubectl get svc
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
kubernetes       ClusterIP   10.96.0.1    <none>        443/TCP    108d
mysql-instance   ClusterIP   None         <none>        3306/TCP   48s
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                        STORAGECLASS   REASON   AGE
mysql-instance-pv                          1Gi        RWO            Retain           Available                                                        52s
pvc-4f192c3b-4be6-44ff-9c23-962e4fd9c9e8   1Gi        RWO            Delete           Bound       default/mysql-instance-pvc   standard                52s
pvc-c141f591-03ac-437f-ad09-376716e36d3b   1Gi        RWO            Delete           Released    default/mysql-instance-pvc   standard                12h
$ kubectl get pvc
NAME                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-instance-pvc   Bound    pvc-4f192c3b-4be6-44ff-9c23-962e4fd9c9e8   1Gi        RWO            standard       59s
~~~

При удалении CustomResource mysql-instance: CR будет удален, но наш контроллер нe удалит ресуры, созданные контроллером,
 т.к. обработки событий на удаление у нас нет.
Для удаления ресурсов, сделаем deployment,svc,pv,pvc дочерними ресурсами к mysql.
Теперь удалим cr mysql-instance и проверяем что deployment, service, pv и pvc уалились:

~~~sh

[2021-01-10 13:54:01,441] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2021-01-10 13:54:01,441] kopf.objects         [INFO    ] [default/mysql-instance] Creation event is processed: 1 succeeded; 0 failed.
[2021-01-10 14:00:43,981] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'delete_object_make_backup' succeeded.
[2021-01-10 14:00:43,982] kopf.objects         [INFO    ] [default/mysql-instance] Deletion event is processed: 1 succeeded; 0 failed.
~~~

и в другом окне:

~~~sh
$ kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted
$ kubectl get deployment.apps
No resources found.
$ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   108d
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                        STORAGECLASS   REASON   AGE
pvc-c141f591-03ac-437f-ad09-376716e36d3b   1Gi        RWO            Delete           Released   default/mysql-instance-pvc   standard                12h
[itokareva@otus kubernetes-operators]$ kubectl get pvc
No resources found.
~~~
Реализуем остальные требования к контроллеру в части создания pv и pvc для backup и написания джобов на создание backup-ов и восстановление.
После доработки контроллера проверяем, что pvc появились.
	
~~~sh
$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    pvc-d771741c-06e4-4cb0-a88d-3d54fc2a9f47   1Gi        RWO            standard       26s
mysql-instance-pvc          Bound    pvc-35b2608b-28d2-4867-84d9-02ec52ece864   1Gi        RWO            standard       27s
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                               STORAGECLASS   REASON   AGE
backup-mysql-instance-pv                   1Gi        RWO            Retain           Available                                                               31s
mysql-instance-pv                          1Gi        RWO            Retain           Available                                                               31s
pvc-35b2608b-28d2-4867-84d9-02ec52ece864   1Gi        RWO            Delete           Bound       default/mysql-instance-pvc          standard                31s
pvc-c141f591-03ac-437f-ad09-376716e36d3b   1Gi        RWO            Delete           Released    default/mysql-instance-pvc          standard                14h
pvc-d771741c-06e4-4cb0-a88d-3d54fc2a9f47   1Gi        RWO            Delete           Bound       default/backup-mysql-instance-pvc   standard                30s
~~~

5) Проверяем работу контроллера

- создаем таблицу test в БД и заполняем ее

~~~sh
mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
2 rows in set (0.00 sec)
~~~
- удалим rc 

~~~sh
$ kubectl delete mysqls.otus.homework mysql-instance
mysql.otus.homework "mysql-instance" deleted

$ kubectl get mysqls.otus.homework mysql-instance
Error from server (NotFound): mysqls.otus.homework "mysql-instance" not found
$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
backup-mysql-instance-pvc   Bound    pvc-d771741c-06e4-4cb0-a88d-3d54fc2a9f47   1Gi        RWO            standard       108m
$ kubectl get pods
NAME                              READY   STATUS      RESTARTS   AGE
backup-mysql-instance-job-lk7md   0/1     Completed   0          74s

$ kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           4s         7m40s
restore-mysql-instance-job   0/1           84m        84m
~~~

- Создадим заново mysql-instance:

~~~sh
$ kubectl exec -it mysql-instance-6785949c48-p7nht /bin/sh
#  mysql -u root -potuspassword otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 4
Server version: 5.7.32 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
2 rows in set (0.00 sec)

mysql>
~~~

6) Собираем докер-образ с контроллером itokareva/mysql:1.0 и выкладываем его на dockerHub

7) Деплой оператора

- останавливаем контроллер
- создаем deployment mysql-operator и применяем его
- проверяем создание cr mysql-instance

~~~sh
$ kubectl apply -f ../deploy/cr.yaml
mysql.otus.homework/mysql-instance created
$ kubectl get mysqls.otus.homework mysql-instance
NAME             AGE
mysql-instance   79s

$ kubectl get jobs.batch
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           3s         9m32s
restore-mysql-instance-job   1/1           52s        7m5s

$ kubectl exec -ti mysql-instance-6785949c48-lzwmb /bin/sh
#  mysql -u root -potuspassword otus-database
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.32 MySQL Community Server (GPL)

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> select * from test;
ERROR 1146 (42S02): Table 'otus-database.test' doesn't exist
mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
2 rows in set (0.00 sec)

~~~
</details>

<details>
  <summary>## Домашняя работа 8</summary>

  ##Мониторинг компонентов кластера и приложений, работающих в нем

Выбран 4 вариант сложности: Поставить при помощи helm3.

1) Должен быть написан Deployment содержащий в себе миниму 3 контейнера nginx.
В файле конфигурации nginx должны присутствовать строки:
~~~yaml

location = /basic_status {
stub_status;
}
~~~ 

Построен докер-образ itokareva/web:3.0 из каталога kubernetes-monitoring/build.

2) Prometheus-operatos, prometheus, grafana и alertmanager развернуты и чарта сообщества:
[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
Поднимала из kubernetes-monitoring/helmfile/helmfile.yaml kube-prometheus-stack и nginx-ingress. 
values - для kube-prometheus-stack взяты из лекции.

~~~sh
helmfile --selector name=kube-prometheus-stack apply
helmfile --selector name=nginx-ingress apply

$ kubectl api-resources | grep prom
prometheuses                                   monitoring.coreos.com          true         Prometheus
prometheusrules                                monitoring.coreos.com          true         PrometheusRule

$ kubectl get crd
NAME                                        CREATED AT
alertmanagerconfigs.monitoring.coreos.com   2021-01-12T18:26:42Z
alertmanagers.monitoring.coreos.com         2021-01-12T18:26:42Z
backendconfigs.cloud.google.com             2021-01-11T22:08:35Z
frontendconfigs.networking.gke.io           2021-01-11T22:08:35Z
managedcertificates.networking.gke.io       2021-01-11T22:08:12Z
podmonitors.monitoring.coreos.com           2021-01-12T18:26:42Z
probes.monitoring.coreos.com                2021-01-12T18:26:43Z
prometheuses.monitoring.coreos.com          2021-01-12T18:26:43Z
prometheusrules.monitoring.coreos.com       2021-01-12T18:26:43Z
scalingpolicies.scalingpolicy.kope.io       2021-01-11T22:08:12Z
servicemonitors.monitoring.coreos.com       2021-01-12T18:26:43Z
storagestates.migration.k8s.io              2021-01-11T22:08:12Z
storageversionmigrations.migration.k8s.io   2021-01-11T22:08:12Z
thanosrulers.monitoring.coreos.com          2021-01-12T18:26:44Z
updateinfos.nodemanagement.gke.io           2021-01-11T22:08:13Z

$ kubectl get prometheuses.monitoring.coreos.com -A
NAMESPACE   NAME                               VERSION   REPLICAS   AGE
default     kube-prometheus-stack-prometheus   v2.22.1   1          13h

$ kubectl get pods
NAME                                                       READY   STATUS    RESTARTS   AGE
alertmanager-kube-prometheus-stack-alertmanager-0          2/2     Running   0          12h
exporter-79cc6bd6d4-tlrtm                                  1/1     Running   2          12h
kube-prometheus-stack-grafana-68455865d7-zwspp             2/2     Running   0          12h
kube-prometheus-stack-kube-state-metrics-bbf56d7f5-fppsq   1/1     Running   0          12h
kube-prometheus-stack-operator-74bb549d85-lgrgc            1/1     Running   0          12h
kube-prometheus-stack-prometheus-node-exporter-82tml       1/1     Running   0          13h
kube-prometheus-stack-prometheus-node-exporter-ffzzc       1/1     Running   0          12h
kube-prometheus-stack-prometheus-node-exporter-k8v4f       1/1     Running   0          12h
kube-prometheus-stack-prometheus-node-exporter-wwl2h       1/1     Running   0          13h
prometheus-kube-prometheus-stack-prometheus-0              2/2     Running   1          12h
web-cc78f4b65-478pb                                        1/1     Running   0          10h
web-cc78f4b65-97ctz                                        1/1     Running   0          10h
web-cc78f4b65-nk7br                                        1/1     Running   0          10h

Prometheus стартовал 2 контейнера config-reloader и prometheus. 
reloader - считывает конфигурацию, если она обновляется по пути: watched_dirs=/etc/prometheus/rules

$ kubectl logs -f prometheus-kube-prometheus-stack-prometheus-0 config-reloader
level=info ts=2021-01-12T22:08:43.879885265Z caller=main.go:147 msg="Starting prometheus-config-reloader" version="(version=0.44.0, branch=refs/tags/pkg/apis/monitoring/v0.44.0, revision=35c9101c332b9371172e1d6cc5a57c065f14eddf)"
level=info ts=2021-01-12T22:08:43.879975363Z caller=main.go:148 build_context="(go=go1.14.12, user=paulfantom, date=20201202-15:44:08)"
level=info ts=2021-01-12T22:08:43.880208301Z caller=main.go:182 msg="Starting web server for metrics" listen=:8080
level=error ts=2021-01-12T22:08:43.885808779Z caller=runutil.go:98 msg="function failed. Retrying in next tick" err="trigger reload: reload request failed: Post \"http://127.0.0.1:9090/-/reload\": dial tcp 127.0.0.1:9090: connect: connection refused"
level=info ts=2021-01-12T22:08:49.001167414Z caller=reloader.go:347 msg="Reload triggered" cfg_in=/etc/prometheus/config/prometheus.yaml.gz cfg_out=/etc/prometheus/config_out/prometheus.env.yaml watched_dirs=/etc/prometheus/rules/prometheus-kube-prometheus-stack-prometheus-rulefiles-0
level=info ts=2021-01-12T22:08:49.001319002Z caller=reloader.go:214 msg="started watching config file and directories for changes" cfg=/etc/prometheus/config/prometheus.yaml.gz out=/etc/prometheus/config_out/prometheus.env.yaml dirs=/etc/prometheus/rules/prometheus-kube-prometheus-stack-prometheus-rulefiles-0
level=info ts=2021-01-13T00:03:54.078778395Z caller=reloader.go:347 msg="Reload triggered" cfg_in=/etc/prometheus/config/prometheus.yaml.gz cfg_out=/etc/prometheus/config_out/prometheus.env.yaml watched_dirs=/etc/prometheus/rules/prometheus-kube-prometheus-stack-prometheus-rulefiles-0
~~~

Контейнер Prometheus эту конфигурацию применил: Completed loading of configuration file

~~~sh
$ kubectl logs -f prometheus-kube-prometheus-stack-prometheus-0 prometheus
level=info ts=2021-01-12T22:08:44.622Z caller=main.go:353 msg="Starting Prometheus" version="(version=2.22.1, branch=HEAD, revision=00f16d1ac3a4c94561e5133b821d8e4d9ef78ec2)"
level=info ts=2021-01-12T22:08:44.623Z caller=main.go:358 build_context="(go=go1.15.3, user=root@516b109b1732, date=20201105-14:02:25)"
level=info ts=2021-01-12T22:08:44.624Z caller=main.go:359 host_details="(Linux 4.19.112+ #1 SMP Sat Oct 10 13:45:37 PDT 2020 x86_64 prometheus-kube-prometheus-stack-prometheus-0 (none))"
level=info ts=2021-01-12T22:08:44.624Z caller=main.go:360 fd_limits="(soft=1048576, hard=1048576)"
level=info ts=2021-01-12T22:08:44.624Z caller=main.go:361 vm_limits="(soft=unlimited, hard=unlimited)"
level=info ts=2021-01-12T22:08:44.628Z caller=main.go:712 msg="Starting TSDB ..."
level=info ts=2021-01-12T22:08:44.640Z caller=head.go:642 component=tsdb msg="Replaying on-disk memory mappable chunks if any"
level=info ts=2021-01-12T22:08:44.640Z caller=head.go:656 component=tsdb msg="On-disk memory mappable chunks replay completed" duration=6.672µs
level=info ts=2021-01-12T22:08:44.641Z caller=head.go:662 component=tsdb msg="Replaying WAL, this may take a while"
level=info ts=2021-01-12T22:08:44.642Z caller=web.go:516 component=web msg="Start listening for connections" address=0.0.0.0:9090
level=info ts=2021-01-12T22:08:44.643Z caller=head.go:714 component=tsdb msg="WAL segment loaded" segment=0 maxSegment=0
level=info ts=2021-01-12T22:08:44.643Z caller=head.go:719 component=tsdb msg="WAL replay completed" checkpoint_replay_duration=68.003µs wal_replay_duration=1.616337ms total_replay_duration=2.839227ms
level=info ts=2021-01-12T22:08:44.645Z caller=main.go:732 fs_type=EXT4_SUPER_MAGIC
level=info ts=2021-01-12T22:08:44.645Z caller=main.go:735 msg="TSDB started"
level=info ts=2021-01-12T22:08:44.645Z caller=main.go:861 msg="Loading configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml
level=info ts=2021-01-12T22:08:44.651Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-12T22:08:44.653Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-12T22:08:44.654Z caller=kubernetes.go:263 component="discovery manager notify" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-12T22:08:44.856Z caller=main.go:892 msg="Completed loading of configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml totalDuration=211.152817ms remote_storage=2.609µs web_handler=650ns query_engine=2.123µs scrape=472.652µs scrape_sd=2.934872ms notify=31.643µs notify_sd=2.414704ms rules=199.891055ms
level=info ts=2021-01-12T22:08:44.856Z caller=main.go:684 msg="Server is ready to receive web requests."
level=info ts=2021-01-12T22:08:48.886Z caller=main.go:861 msg="Loading configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml
level=warn ts=2021-01-12T22:08:48.892Z caller=klog.go:88 component=k8s_client_runtime func=Warningf msg="/app/discovery/kubernetes/kubernetes.go:426: watch of *v1.Endpoints ended with: an error on the server (\"unable to decode an event from the watch stream: context canceled\") has prevented the request from succeeding"
level=info ts=2021-01-12T22:08:48.892Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-12T22:08:48.894Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=warn ts=2021-01-12T22:08:48.895Z caller=klog.go:88 component=k8s_client_runtime func=Warningf msg="/app/discovery/kubernetes/kubernetes.go:428: watch of *v1.Pod ended with: an error on the server (\"unable to decode an event from the watch stream: context canceled\") has prevented the request from succeeding"
level=info ts=2021-01-12T22:08:48.901Z caller=kubernetes.go:263 component="discovery manager notify" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-12T22:08:49.000Z caller=main.go:892 msg="Completed loading of configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml totalDuration=113.873881ms remote_storage=3.535µs web_handler=700ns query_engine=2.104µs scrape=117.206µs scrape_sd=3.213284ms notify=16.846µs notify_sd=8.466241ms rules=96.67985ms
level=info ts=2021-01-13T00:03:53.972Z caller=main.go:861 msg="Loading configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml
level=warn ts=2021-01-13T00:03:53.987Z caller=klog.go:88 component=k8s_client_runtime func=Warningf msg="/app/discovery/kubernetes/kubernetes.go:428: watch of *v1.Pod ended with: an error on the server (\"unable to decode an event from the watch stream: context canceled\") has prevented the request from succeeding"
level=warn ts=2021-01-13T00:03:53.987Z caller=klog.go:88 component=k8s_client_runtime func=Warningf msg="/app/discovery/kubernetes/kubernetes.go:427: watch of *v1.Service ended with: an error on the server (\"unable to decode an event from the watch stream: context canceled\") has prevented the request from succeeding"
level=info ts=2021-01-13T00:03:53.988Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-13T00:03:53.991Z caller=kubernetes.go:263 component="discovery manager scrape" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-13T00:03:53.992Z caller=kubernetes.go:263 component="discovery manager notify" discovery=kubernetes msg="Using pod service account via in-cluster config"
level=info ts=2021-01-13T00:03:54.078Z caller=main.go:892 msg="Completed loading of configuration file" filename=/etc/prometheus/config_out/prometheus.env.yaml totalDuration=105.950693ms remote_storage=3.814µs web_handler=25.531µs query_engine=5.405µs scrape=5.866621ms scrape_sd=5.913939ms notify=87.282µs notify_sd=1.518519ms rules=83.966314ms
~~~

[nginx-connections-overview](./nginx_connections.png) 
[nginx-metrics](./nginx_metrics.png)


3) развернут [nginx-prometheus-exporter](https://github.com/nginxinc/nginx-prometheus-exporter)

 - построен образ itokareva/nginx-prometheus-exporter:1.0
 - deployment и service подняты из kubernetes-monitoring/nginx-prometheus-exporter 

 Экспортеру передается аргумент:
 args: [ "-nginx.scrape-uri", "http://web-svc/basic_status" ]

 после развертывания метрики доступны по: http://web-svc/basic_status

 ![nginx_metrics](kubernetes-monitoring/nginx_metrics.png) 

 4) поднят servicemonitor из kubernetes-monitoring/serviceMonitor.yaml

~~~sh
$ kubectl api-resources | grep servicemon
servicemonitors                                monitoring.coreos.com          true         ServiceMonitor
~~~

 5) Построен дашборд в графане с метриками nginx

 ![nginx-dashboard](kubernetes-monitoring/nginx_connections.png)

</details>

<details>
  <summary>## Домашняя работа 9</summary>

  ##Сервисы централизованного логирования для компонентов Kubernetes и приложений

1) Развернут кластер с помощью terraform. Скрипты для развертывания в каталоге kubernetes-logging/terraform
	
2) Установлено приложение hipster:
kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platformsnippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n
microservices-demo
3) Установлен EFK-стэк, prometheus, grafana, nginx-ingress, elasticsearch-exporter  с помощью helmfile:

helmfile --selector name=nginx-ingress apply
helmfile --selector name=kibana	 apply
helmfile --selector name=elasticsearch apply
helmfile --selector name=fluent-bit apply
helmfile --selector name=kube-prometheus-stack apply
helmfile --selector name=elasticsearch-exporter apply

4) в графану залит популярный дашборд для мониторинга elasticsearch:


![elasticsearch_dashboard_green](kubernetes-logging/elasticsearch_dashboard_green.png) 

    
  Рассмотрены несколько метрик для мониторинга: 

- unassigned_shards       - количество shard, для которых не нашлось 
                            подходящей ноды, их наличие сигнализирует о проблемах
- jvm_memory_usage        - высокая загрузка (в процентах от выделенной памяти) может привести к замедлению работы кластера
- number_of_pending_tasks - количество задач, ожидающих выполнения.
                            Значение метрики, отличное от нуля, может сигнализировать о наличии проблем внутри кластера

  Больше метрик [здесь](https://habr.com/ru/company/yamoney/blog/358550/)

5) Добиваемся, чтобы появились логи nginx-ingress в kibana:

    serviceMonitor:
      enabled: true

6) Добиваемся, чтобы кроме логов писались и метрики:

~~~sh
  metrics:
    enabled: true
    service:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "10254"
~~~	
	
7) Мы можем использовать полнотекстовый поиск, но лишены возможности: 

   - Задействовать функции
   - Полноценно проводить аналитику
   - Создавать Dashboard по логам
 
   Добиваемся, чтобы эта возможность появилась следующей настройкой:

~~~sh
  config:
    log-format-escape-json: "true"
    log-format-upstream: '{"timestamp": "$time_iso8601",
    "requestID": "$req_id",
    "proxyUpstreamName": "$proxy_upstream_name",
    "proxyAlternativeUpstreamName": "$proxy_alternative_upstream_name",
    "upstreamStatus": "$upstream_status",
    "upstreamAddr": "$upstream_addr",
    "x-forward-for": "$proxy_add_x_forwarded_for",
    "httpRequest":{"requestMethod": "$request_method", "requestUrl": "$host$request_uri",
    "status": $status,"requestSize": "$request_length", "responseSize": "$upstream_response_length",
    "userAgent": "$http_user_agent", "remoteIp": "$remote_addr", "referer": "$http_referer",
    "latency": "$upstream_response_time s", "protocol":"$server_protocol"}}'
~~~

8) Логи попадают в kibana  нужном нам формате:

~~~sh
{
  "_index": "kubernetes_cluster-2021.01.21",
  "_type": "flb_type",
  "_id": "Un00J3cBnapfXRBRSQ8S",
  "_version": 1,
  "_score": null,
  "_source": {
    "@timestamp": "2021-01-21T23:07:53.093Z",
    "log": "{\"timestamp\": \"2021-01-21T23:07:53+00:00\", \"requestID\": \"84dcb10280b68eae74ec7e295d3adee6\", \"proxyUpstreamName\": \"observability-kibana-kibana-5601\", \"proxyAlternativeUpstreamName\": \"\", \"upstreamStatus\": \"200\", \"upstreamAddr\": \"10.108.0.3:5601\", \"x-forward-for\": \"10.166.0.4\", \"httpRequest\":{\"requestMethod\": \"POST\", \"requestUrl\": \"kibana.35.228.112.27.xip.io/internal/search/ese/FmxLNENaTkVKUWtxZjRPU1pDZHZtNEEdX3A5dWhtS1VUTW10MXlpTHY2UjJiQToyMDM2NDk=\", \"status\": 200,\"requestSize\": \"1374\", \"responseSize\": \"3064\", \"userAgent\": \"Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0\", \"remoteIp\": \"10.166.0.4\", \"referer\": \"http://kibana.35.228.112.27.xip.io/app/discover\", \"latency\": \"0.044 s\", \"protocol\":\"HTTP/1.1\"}}\n",
    "stream": "stdout",
    "requestID": "84dcb10280b68eae74ec7e295d3adee6",
    "proxyUpstreamName": "observability-kibana-kibana-5601",
    "proxyAlternativeUpstreamName": "",
    "upstreamStatus": "200",
    "upstreamAddr": "10.108.0.3:5601",
    "x-forward-for": "10.166.0.4",
    "httpRequest": {
      "requestMethod": "POST",
      "requestUrl": "kibana.35.228.112.27.xip.io/internal/search/ese/FmxLNENaTkVKUWtxZjRPU1pDZHZtNEEdX3A5dWhtS1VUTW10MXlpTHY2UjJiQToyMDM2NDk=",
      "status": 200,
      "requestSize": "1374",
      "responseSize": "3064",
      "userAgent": "Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
      "remoteIp": "10.166.0.4",
      "referer": "http://kibana.35.228.112.27.xip.io/app/discover",
      "latency": "0.044 s",
      "protocol": "HTTP/1.1"
    },
    "kubernetes": {
      "pod_name": "nginx-ingress-controller-568bd996bf-2b468",
      "namespace_name": "nginx-ingress",
      "pod_id": "144fe111-38c5-4945-a9f5-7128b3e7a2fc",
      "labels": {
        "app": "nginx-ingress",
        "app_kubernetes_io/component": "controller",
        "component": "controller",
        "pod-template-hash": "568bd996bf",
        "release": "nginx-ingress"
      },
      "host": "gke-omega-default-pool-f0c3f949-fn7r",
      "container_name": "nginx-ingress-controller",
      "docker_id": "efc9306cecac3eec8fc595222849f47a0719afcbb4fe3f67fde69c78be375de0",
      "container_hash": "0e072dddd1f7f8fc8909a2ca6f65e76c5f0d2fcfb8be47935ae3457e8bbceb20"
    }
  },
  "fields": {
    "@timestamp": [
      "2021-01-21T23:07:53.093Z"
    ]
  },
  "highlight": {
    "kubernetes.labels.app": [
      "@kibana-highlighted-field@nginx@/kibana-highlighted-field@-ingress"
    ],
    "kubernetes.container_name": [
      "@kibana-highlighted-field@nginx@/kibana-highlighted-field@-ingress-controller"
    ],
    "kubernetes.pod_name": [
      "@kibana-highlighted-field@nginx@/kibana-highlighted-field@-ingress-controller-568bd996bf-2b468"
    ],
    "kubernetes.labels.release": [
      "@kibana-highlighted-field@nginx@/kibana-highlighted-field@-ingress"
    ],
    "kubernetes.namespace_name": [
      "@kibana-highlighted-field@nginx@/kibana-highlighted-field@-ingress"
    ]
  },
  "sort": [
    1611270473093
  ]
}
~~~

9) Опробованы возможности kibana для визуализации: Visualize. Созданы визуализации для отображения запросов к
   nginx-ingress со статусами:

- 200-299
- 300-399
- 400-499
- 500+

10) Создан дашборд с созданными визуализациями и выгружен в формате json в kubernetes-logging/export.ndjson

11) установлены loki с помощью helmfile:

helmfile --selector name=loki apply

12) создан дашборд в граафане, на котором одновременно выведем метрики nginx-ingress и его логи:

    - созданы переменные: namespace, controller class, controller
    - добавлена панель с графтком неуспешных запросов в разрезе инстансов nginx-ingress
    - добавлена панель с графиком успешных запросов в разрезе сервисов (grafana, prometheus, kibana)
    - добавлена панель с логами	 
    - выгружен из Grafana JSON с финальным Dashboard и помесщен в файл kubernetes-logging/nginx-ingress.json
![nginx-ingress_dashboards_and_logs](kubernetes-logging/nginx-ingress_dashboards_and_logs.png)

13) Задание со (*)
 
    Для централизованного просмотра централизованного логов с виртуальных машин, на которых запущен Kubernetes в
конфигурацию fluent-bit добавлены секции:

~~~sh
  [INPUT]
      Name syslog
      Path /tmp/in_syslog
      Buffer_Chunk_Size 32000
      Buffer_Max_Size 64000
  [INPUT]
      Name mem
      Tag memory
~~~

    Пишутся логи такого типа:

~~~sh
Jan 26, 2021 @ 17:46:06.304

log:
    [2021/01/26 14:46:06] [ info] [input] pausing syslog.1 
@timestamp:
    Jan 26, 2021 @ 17:46:06.304
stream:
    stderr
kubernetes.pod_name:
    fluent-bit-lhn5g
kubernetes.namespace_name:
    observability
kubernetes.pod_id:
    8549dec8-1e5d-45ff-8a25-1dbb9a86e878
kubernetes.labels.app:
    fluent-bit
kubernetes.labels.controller-revision-hash:
    6fd958bb
kubernetes.labels.pod-template-generation:
    5
kubernetes.labels.release:
    fluent-bit
kubernetes.annotations.checksum/config:
    7782465e7df8adf15a2042b45128bfb1f6ea7e662387ce568c68659fd5d4c23e
kubernetes.host:
    gke-omega-infra-9b71ecbe-3rbt
kubernetes.container_name:
    fluent-bit
kubernetes.docker_id:
    05fadefcd28a67c8402ac86fdb36fbcd49c6ab5257ae3c90df39ca2d7d3bf5bf
kubernetes.container_hash:
    3ae8c4ee81c570155f2b37e024ad6922b89aea471ed4c07bd919e2656d758d93
_id:
    -xUoP3cBBd5omGi7sYNo
_type:
    flb_type
_index:
    kubernetes_cluster-2021.01.26
_score:
    - 
~~~

~~~sh
{
  "_index": "kubernetes_cluster-2021.01.26",
  "_type": "flb_type",
  "_id": "CRuDP3cBBd5omGi7Q8-s",
  "_version": 1,
  "_score": null,
  "_source": {
    "@timestamp": "2021-01-26T16:24:58.071Z",
    "log": "[618] kube.var.log.containers.fluent-bit-ngmr2_observability_fluent-bit-b4233e9de4ba68d47739d5f22e2233fc7b7d63d377e7e11c398d0837b8165a5e.log: [1611678296.070027840, {\"log\"=>\"[591] kube.var.log.containers.fluent-bit-ngmr2_observability_fluent-bit-b4233e9de4ba68d47739d5f22e2233fc7b7d63d377e7e11c398d0837b8165a5e.log: [1611678295.041866822, {\"log\"=>\"[0] memory: [1611678295.000076125, {\"Mem.total\"=>7656544, \"Mem.used\"=>3786328, \"Mem.free\"=>3870216, \"Swap.total\"=>0, \"Swap.used\"=>0, \"Swap.free\"=>0}]\n",
    "stream": "stdout",
    "kubernetes": {
      "pod_name": "fluent-bit-ngmr2",
      "namespace_name": "observability",
      "pod_id": "ce663e91-7a01-4557-b2d0-bcd19a510c61",
      "labels": {
        "app": "fluent-bit",
        "controller-revision-hash": "66896b5464",
        "pod-template-generation": "10",
        "release": "fluent-bit"
      },
      "annotations": {
        "checksum/config": "b82084ef45bb706cdde7e18488e4d98181e62abd51eb46c6388dfee642240a51"
      },
      "host": "gke-omega-infra-9b71ecbe-1ght",
      "container_name": "fluent-bit",
      "docker_id": "b4233e9de4ba68d47739d5f22e2233fc7b7d63d377e7e11c398d0837b8165a5e",
      "container_hash": "3ae8c4ee81c570155f2b37e024ad6922b89aea471ed4c07bd919e2656d758d93"
    }
  },
  "fields": {
    "@timestamp": [
      "2021-01-26T16:24:58.071Z"
    ]
  },
  "highlight": {
    "log": [
      "[618] kube.var.log.containers.fluent-bit-ngmr2_observability_fluent-bit-b4233e9de4ba68d47739d5f22e2233fc7b7d63d377e7e11c398d0837b8165a5e.log: [1611678296.070027840, {\"log\"=>\"[591] kube.var.log.containers.fluent-bit-ngmr2_observability_fluent-bit-b4233e9de4ba68d47739d5f22e2233fc7b7d63d377e7e11c398d0837b8165a5e.log: [1611678295.041866822, {\"log\"=>\"[0] @kibana-highlighted-field@memory@/kibana-highlighted-field@: [1611678295.000076125, {\"Mem.total\"=>7656544, \"Mem.used\"=>3786328, \"Mem.free\"=>3870216, \"Swap.total\"=>0, \"Swap.used\"=>0, \"Swap.free\"=>0}]"
    ]
  },
  "sort": [
    1611678298071
  ]
}
~~~
    а так же для выполнения Health-check Prometheus и Grafana добавлена секция:
~~~sh
  [INPUT]
      Name healthGrafana
      Host grafana
      Port 80
      Interval_Sec 1
      Interval_NSec 0
  [INPUT]
      Name healthProm
      Host prometheus
      Port 80
      Interval_Sec 1
      Interval_NSec 0
~~~

    Пишутся логи такоготипа:

~~~sh
[0] health.3: [1611676752.005641571, {"alive"=>true}]
[0] health.4: [1611676752.005717856, {"alive"=>true}]
[0] health.3: [1611676753.005669042, {"alive"=>true}]
[0] health.4: [1611676753.005713119, {"alive"=>true}]
[0] health.3: [1611676754.005435655, {"alive"=>true}]
[0] health.4: [1611676754.005489831, {"alive"=>true}]
[0] health.3: [1611676755.005106009, {"alive"=>true}]
[0] health.4: [1611676755.005157471, {"alive"=>true}]
[0] health.3: [1611676756.004872492, {"alive"=>true}]
[0] health.4: [1611676756.004906487, {"alive"=>true}]
~~~
	
</details>

<details>
  <summary>## Домашняя работа 10</summary>

## GitOps и инструменты поставки
 
## GitOps. Flux

1) В качестве хранилища кода и CI-системы в домашнем задании мы будем использовать SaaS GitLab. 
2) После этого создадим в GitLab публичный проект microservicesdemo.
3) Подготовили Helm чарты для каждого микросервиса deploy/charts.
4) Тарраформом развернут kubernetes-кластер в GCP.
5) Собрали Docker образы для всех микросервиса и поместили данные образы в Docker Hub.
6) Flux, Helm operator установлены с помощью helmfile.
7) Поместили манифест, описывающий namespace microservices-demo в директорию deploy/namespaces и сделали push в GitLab. 
  В кластере создался namespace microservices-demo, а в логах pod с flux должна появилась строка, описывающая
  действия данного инструмента:

~~~sh
ts=2021-02-04T06:55:16.442764981Z caller=sync.go:61 component=daemon info="trying to sync git changes to the cluster" old= new=538532af11dae6f915fcf23cc98274e2628d0352
ts=2021-02-04T06:55:17.91597765Z caller=sync.go:540 method=Sync cmd=apply args= count=1
ts=2021-02-04T06:55:18.575418201Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=659.344812ms err=null output="namespace/microservices-demo created"
~~~
8) Создали сущность, которой управляет helm-operator - HelmRelease. Это frontend.yaml с описанием конфигурации релиза.
   Поместили его в deploy/releases. После выполнения push gitlab master видим, что наш release frontend не может выполнить sync в кластер:

~~~sh
  Warning  FailedReleaseSync  12m                  helm-operator  synchronization of release 'frontend' in namespace 'microservices-demo' failed: failed to prepare chart for release: chart not ready: no existing git mirror found
  Warning  FailedReleaseSync  12m                  helm-operator  synchronization of release 'frontend' in namespace 'microservices-demo' failed: failed to prepare chart for release: chart not ready: git repo has not been cloned yet
  Warning  FailedReleaseSync  2m8s (x20 over 12m)  helm-operator  synchronization of release 'frontend' in namespace 'microservices-demo' failed: installation failed: unable to build kubernetes objects from release manifest: unable to recognize "": no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
~~~

это потому что, в репозитории gitlab microservices-demo/deploy/charts/frontend/templates/serviceMonitor.yaml описывает kind: ServiceMonitor, для которого нет crd.

~~~sh
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  namespaceSelector:
    matchNames:
    - {{ .Release.Namespace }}
  endpoints:
  - port: http
~~~ 
   Создадим его.

~~~sh
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.45.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
~~~

   Теперь sync произошел успешно:

~~~sh
Normal   ReleaseSynced      7s (x3 over 107s)    helm-operator  managed release 'frontend' in namespace 'microservices-demo' synchronized

$ kubectl get helmrelease -n microservices-demo
NAME       RELEASE    PHASE       STATUS     MESSAGE                                                                       AGE
frontend   frontend   Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.   17m

helm list -n microservices-demo
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART           APP VERSION
frontend        microservices-demo      1               2021-02-06 10:03:24.313965777 +0000 UTC deployed        frontend-0.21.0 1.16.0
~~~

   Можем выполнить синхронизацию вручную:

~~~sh
$ fluxctl --k8s-fwd-ns flux sync
Synchronizing with ssh://git@gitlab.com/otus_hw/microservices-demo.git
Revision of master to apply is 7679592
Waiting for 7679592 to be applied ...
Done.
~~~

9) Пересобран образ с инкрементацией версии тега до v0.0.2. Релиз автоматически обновился в кластере. 

![frontend_v0.0.2](kubernetes-gitops/frontend_v0.0.2.png)

  Для просмотра ревизий релиза можно использовать команду:

~~~sh
$ helm history frontend -n microservices-demo
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
1               Sat Feb  6 10:03:24 2021        superseded      frontend-0.21.0 1.16.0          Install complete
2               Sat Feb  6 10:50:22 2021        deployed        frontend-0.21.0 1.16.0          Upgrade complete
~~~

   В git-репозитории тоже видим, что тэг изменился на v0.0.2.

![commit](kubernetes-gitops/commit.png)
![gitlab_frontend](kubernetes-gitops/gitlab_frontend.png) 

10) Попробуем внести изменения в Helm chart frontend и поменять имя deployment на frontend-hipster. 
   После применения push в GitLab в логе helm-operator видим, что создан новый Deployment called \"frontend-hipster\" in microservices-demo.

~~~sh
info="starting sync run"
ts=2021-02-06T11:38:46.453232885Z caller=release.go:353 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="running upgrade" action=upgrade
ts=2021-02-06T11:38:46.484401878Z caller=helm.go:69 component=helm version=v3 info="preparing upgrade for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.488910245Z caller=helm.go:69 component=helm version=v3 info="resetting values to the chart's original version" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.710112201Z caller=helm.go:69 component=helm version=v3 info="performing update for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.781978566Z caller=helm.go:69 component=helm version=v3 info="creating upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.799502347Z caller=helm.go:69 component=helm version=v3 info="checking 5 resources for changes" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.808629453Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Service \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.825379548Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.834904108Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for Gateway \"frontend-gateway\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.852498528Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for ServiceMonitor \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.870788415Z caller=helm.go:69 component=helm version=v3 info="Looks like there are no changes for VirtualService \"frontend\"" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.883253696Z caller=helm.go:69 component=helm version=v3 info="Deleting \"frontend\" in microservices-demo..." targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:46.924709185Z caller=helm.go:69 component=helm version=v3 info="updating status for upgraded release for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:47.004127464Z caller=release.go:364 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="upgrade succeeded" revision=af9975bbf52055b7258a45552c300da38ae27459 phase=upgrade
~~~ 

  Механизм работы оператора - это постоянный опрос репозитория GitLab на наличие изменений: info="no changes" phase=dry-run-compare

~~~sh
info="starting sync run"
ts=2021-02-06T11:38:04.614981202Z caller=release.go:289 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="running dry-run upgrade to compare with release version '2'" action=dry-run-compare
ts=2021-02-06T11:38:04.617465315Z caller=helm.go:69 component=helm version=v3 info="preparing upgrade for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:04.625723751Z caller=helm.go:69 component=helm version=v3 info="resetting values to the chart's original version" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:05.043351507Z caller=helm.go:69 component=helm version=v3 info="performing update for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:05.123770534Z caller=helm.go:69 component=helm version=v3 info="dry run for frontend" targetNamespace=microservices-demo release=frontend
ts=2021-02-06T11:38:05.143749332Z caller=release.go:311 component=release release=frontend targetNamespace=microservices-demo resource=microservices-demo:helmrelease/frontend helmVersion=v3 info="no changes" phase=dry-run-compare
~~~
11) Добавили манифесты HelmRelease для всех микросервисов входящих в состав HipsterShop.
   Все микросервисы кроме loadgenerator успешно развернулись в Kubernetes кластере.
![k8s-microservices-demo](kubernetes-gitops/k8s-microservices-demo.png)

## Canary deployments с Flagger и Istio

1) Установили flagger через helmfile
2) Установили istio через GKE add-on
3) Изменено созданное ранее описание namespace microservices-demo, как istio-injection: enabled
4) Самый простой способ добавить sidecar контейнер в уже запущенные pod - удалить их
5) После этого можно проверить, что контейнер с названием istioproxy появился внутри каждого pod

~~~sh
$ kubectl delete pods --all -n microservices-demo
$ kubectl get ns microservices-demo --show-labels
NAME                 STATUS   AGE     LABELS
microservices-demo   Active   3d14h   fluxcd.io/sync-gc-mark=sha256.Hs9UhrkDHGgPHng6V2omaoGB2F2rxI8Tii0vVt9vFGM,istio-injection=enabled
~~~ 

<details>
  <summary> Контейнер с названием istio-proxy появился внутри каждого pod</summary>

~~~sh
$ kubectl describe pod -l app=frontend -n microservices-demo
Name:           frontend-hipster-556c8b6f49-cvwj9
Namespace:      microservices-demo
Priority:       0
Node:           gke-omega-omega-pool-baef92b9-8ztc/10.166.15.218
Start Time:     Mon, 08 Feb 2021 00:24:05 +0300
Labels:         app=frontend
                pod-template-hash=556c8b6f49
                security.istio.io/tlsMode=istio
Annotations:    sidecar.istio.io/status:
                  {"version":"e08c22464c16dcd08d4d59263d2012385a58bd5e7871a19f2ea2ef2de85ceba3","initContainers":["istio-init"],"containers":["istio-proxy"]...
Status:         Running
IP:             10.108.5.7
Controlled By:  ReplicaSet/frontend-hipster-556c8b6f49
Init Containers:
  istio-init:
    Container ID:  docker://44a85840e44219c81489ad3cc065b744b65b0d7559ef51e6546dde1253ed2d2f
    Image:         gke.gcr.io/istio/proxyv2:1.4.10-gke.7
    Image ID:      docker-pullable://gke.gcr.io/istio/proxyv2@sha256:23964729d1fa5a853bf77f76c506da16ea37547603ed91321e17523e7741f007
    Port:          <none>
    Host Port:     <none>
    Command:
      istio-iptables
      -p
      15001
      -z
      15006
      -u
      1337
      -m
      REDIRECT
      -i
      *
      -x

      -b
      *
      -d
      15020
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Mon, 08 Feb 2021 00:24:11 +0300
      Finished:     Mon, 08 Feb 2021 00:24:12 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     100m
      memory:  50Mi
    Requests:
      cpu:        10m
      memory:     10Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-b2qqg (ro)
Containers:
  server:
    Container ID:   docker://8e5a11636e955fbf9c84b1a2e0337057792b7121da58666febb29f6fe8530156
    Image:          itokareva/frontend:v0.0.2
    Image ID:       docker-pullable://itokareva/frontend@sha256:ffa410a06cc23df8b2dc84f983e8ed1ff22a7b73a8fdb2acaf27aeb31057c94e
    Port:           8080/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 08 Feb 2021 00:24:40 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:      100m
      memory:   64Mi
    Liveness:   http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:
      PORT:                          8080
      PRODUCT_CATALOG_SERVICE_ADDR:  productcatalogservice:3550
      CURRENCY_SERVICE_ADDR:         currencyservice:7000
      CART_SERVICE_ADDR:             cartservice:7070
      RECOMMENDATION_SERVICE_ADDR:   recommendationservice:8080
      SHIPPING_SERVICE_ADDR:         shippingservice:50051
      CHECKOUT_SERVICE_ADDR:         checkoutservice:5050
      AD_SERVICE_ADDR:               adservice:9555
      JAEGER_SERVICE_ADDR:           jaeger-collector.observability.svc.cluster.local:14268
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-b2qqg (ro)
  istio-proxy:
    Container ID:  docker://6751a27f7b1056b380255093523c5fd3f66be3ca4cf9443fdb99a1f6ae089248
    Image:         gke.gcr.io/istio/proxyv2:1.4.10-gke.7
    Image ID:      docker-pullable://gke.gcr.io/istio/proxyv2@sha256:23964729d1fa5a853bf77f76c506da16ea37547603ed91321e17523e7741f007
    Port:          15090/TCP
    Host Port:     0/TCP
    Args:
      proxy
      sidecar
      --domain
      $(POD_NAMESPACE).svc.cluster.local
      --configPath
      /etc/istio/proxy
      --binaryPath
      /usr/local/bin/envoy
      --serviceCluster
      frontend.$(POD_NAMESPACE)
      --drainDuration
      45s
      --parentShutdownDuration
      1m0s
      --discoveryAddress
      istio-pilot.istio-system:15010
      --zipkinAddress
      zipkin.istio-system:9411
      --dnsRefreshRate
      300s
      --connectTimeout
      10s
      --proxyAdminPort
      15000
      --concurrency
      2
      --controlPlaneAuthPolicy
      NONE
      --statusPort
      15020
      --applicationPorts
      8080
    State:          Running
      Started:      Mon, 08 Feb 2021 00:24:41 +0300
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:      100m
      memory:   128Mi
    Readiness:  http-get http://:15020/healthz/ready delay=1s timeout=1s period=2s #success=1 #failure=30
    Environment:
      POD_NAME:                          frontend-hipster-556c8b6f49-cvwj9 (v1:metadata.name)
      ISTIO_META_POD_PORTS:              [
                                             {"name":"http","containerPort":8080,"protocol":"TCP"}
                                         ]
      ISTIO_META_CLUSTER_ID:             Kubernetes
      POD_NAMESPACE:                     microservices-demo (v1:metadata.namespace)
      INSTANCE_IP:                        (v1:status.podIP)
      SERVICE_ACCOUNT:                    (v1:spec.serviceAccountName)
      ISTIO_META_POD_NAME:               frontend-hipster-556c8b6f49-cvwj9 (v1:metadata.name)
      ISTIO_META_CONFIG_NAMESPACE:       microservices-demo (v1:metadata.namespace)
      SDS_ENABLED:                       false
      ISTIO_META_INTERCEPTION_MODE:      REDIRECT
      ISTIO_META_INCLUDE_INBOUND_PORTS:  8080
      ISTIO_METAJSON_LABELS:             {"app":"frontend","pod-template-hash":"556c8b6f49"}

      ISTIO_META_WORKLOAD_NAME:          frontend-hipster
      ISTIO_META_OWNER:                  kubernetes://apis/apps/v1/namespaces/microservices-demo/deployments/frontend-hipster
    Mounts:
      /etc/certs/ from istio-certs (ro)
      /etc/istio/proxy from istio-envoy (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-b2qqg (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-b2qqg:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-b2qqg
    Optional:    false
  istio-envoy:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     Memory
    SizeLimit:  <unset>
  istio-certs:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  istio.default
    Optional:    true
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age   From                                         Message
  ----    ------     ----  ----                                         -------
  Normal  Scheduled  55s   default-scheduler                            Successfully assigned microservices-demo/frontend-hipster-556c8b6f49-cvwj9 to gke-omega-omega-pool-baef92b9-8ztc
  Normal  Pulling    54s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Pulling image "gke.gcr.io/istio/proxyv2:1.4.10-gke.7"
  Normal  Pulled     49s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Successfully pulled image "gke.gcr.io/istio/proxyv2:1.4.10-gke.7"
  Normal  Created    49s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Created container istio-init
  Normal  Started    49s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Started container istio-init
  Normal  Pulling    47s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Pulling image "itokareva/frontend:v0.0.2"
  Normal  Pulled     20s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Successfully pulled image "itokareva/frontend:v0.0.2"
  Normal  Created    20s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Created container server
  Normal  Started    20s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Started container server
  Normal  Pulled     20s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Container image "gke.gcr.io/istio/proxyv2:1.4.10-gke.7" already present on machine
  Normal  Created    19s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Created container istio-proxy
  Normal  Started    19s   kubelet, gke-omega-omega-pool-baef92b9-8ztc  Started container istio-proxy
~~~

</details>

6) Чтобы настроить маршрутизацию трафика к приложению с использованием Istio, нам необходимо добавить ресурсы Gateway и VirtualService.
   Дополнили наш Helm chart frontend манифестами gateway.yaml и virtualService.yaml. 
7) Добавили в Helm chart frontend еще один файл - canary.yaml. В нем будем хранить описание стратегии, по которой необходимо
обновлять данный микросервис.
Узнать подробнее о Canary Custom Resource можно по [ссылке](https://docs.flagger.app/how-it-works#canary-custom-resource)
8) Проверим, что Flagger Успешно инициализировал canary ресурс frontend:
~~~sh
$ kubectl get canary -n microservices-demo
NAME       STATUS        WEIGHT   LASTTRANSITIONTIME
frontend   Initialized   0        2021-02-23T18:46:35Z
~~~
   Обновил pod, добавив ему к названию постфикс primary:
~~~sh
$ kubectl get pods -n microservices-demo -l app=frontend-primary
NAME                                READY   STATUS    RESTARTS   AGE
frontend-primary-6498d4c8d9-6xs52   2/2     Running   0          19m
~~~

9) Попробуем провести релиз. Соберали новый образ frontend с тегом v0.0.3 и сделали push в Docker Hub.
   Релиз в GitLab обновился, но в кластере версия образа frontend не изменилась. Канарейка не запустилась.

   Flagger для старта канарейки использует prometheus, но он не был установлен GKE add-on-ом.
   Аддон установил 1.4.10 версию istio, поэтому был выполнен [Download the Istio release.](https://istio.io/latest/docs/setup/getting-started/#download) 
   
~~~sh
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.4.10 TARGET_ARCH=x86_64 sh -
istioctl install --set profile=demo -y
~~~
   istioctl установил prometheus, но канарейка так и не взлетела и релиз так и не ушел в кластер.
   
   Чтобы посмотреть метрики в prometheus и найти нужную нам request-success-rate был создан GateWay и VirtualService для prometheus:
   [Remotely Accessing Telemetry Addons](https://istio.io/latest/docs/tasks/observability/gateways/#option-2-insecure-access-http)
   п.3 Apply the following configuration to expose Prometheus.
   [canary-custom-resource](https://docs.flagger.app/usage/how-it-works#canary-custom-resource)  
~~~sh
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
echo $INGRESS_DOMAIN
35.228.152.13.nip.io

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: prometheus-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-prom
      protocol: HTTP
    hosts:
    - "prometheus.${INGRESS_DOMAIN}"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: prometheus-vs
  namespace: istio-system
spec:
  hosts:
  - "prometheus.${INGRESS_DOMAIN}"
  gateways:
  - prometheus-gateway
  http:
  - route:
    - destination:
        host: prometheus
        port:
          number: 9090
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: prometheus
  namespace: istio-system
spec:
  host: prometheus
  trafficPolicy:
    tls:
      mode: DISABLE
~~~  
  
   [Заходим в prometheus по ссылке](http://prometheus.35.228.114.139.nip.io/)
   
   Метрики request-success-rate в prometheus так и не нашлось.
   - Откатила istio аддон в ui google cloud.
   - Подняла версию GKE до 1.17.17-gke.1100 (требование при установке Istio 1.9)
   - Установила Istio 1.9.
   
~~~sh 
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.9.0 TARGET_ARCH=x86_64 sh -
cd istio-1.9.1
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
~~~
   В Istio 1.9. prometheus нужно устанавливать отдельно:

~~~sh
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.9/samples/addons/prometheus.yaml
~~~
[Prometheus](https://istio.io/latest/docs/ops/integrations/prometheus/#Configuration)
	  
Метрики request-success-rate так и не нашлось. По документации вместе с Istio ставятся [Istio Standard Metrics](https://istio.io/latest/docs/reference/config/metrics/)

Все они присутствуют в прометее:

![Все они присутствуют в прометее](kubernetes-gitops/Istio_Standard_Metrics.png)

Обранилась к рекомендации:
"Рекомендуется обратить внимание на Helm chart loadgenerator и
модифицировать его таким образом, чтобы нагрузка
генерировалась на внешний, по отношению к кластеру, URL (тем
самым - создав имитацию реального поведения пользователей)"

Внесла в параметры адрес нашего [frontend](https://gitlab.com/otus_hw/microservices-demo/-/blob/master/deploy/charts/loadgenerator/values.yaml).
Сервис loadgenerator успешно поднялся. И стал имитировать работу пользователей. Это важно для работы канарейки: сервис должин быть "живым",
так как наша метрика проверяет количество успешных запросов.

После всего проделанного выполнила rebuild frontend v.0.0.4. 
Сначала обновилась версия [релиза](https://gitlab.com/otus_hw/microservices-demo/-/blob/master/deploy/releases/frontend.yaml)
Затем отработала канарейка и обновила версию сервиса в кластере:

~~~sh
kubectl describe canary frontend -n microservices-demo
Name:         frontend
Namespace:    microservices-demo
Labels:       <none>
Annotations:  helm.fluxcd.io/antecedent: microservices-demo:helmrelease/frontend-hipster
API Version:  flagger.app/v1beta1
Kind:         Canary
Metadata:
  Creation Timestamp:  2021-02-23T18:46:02Z
  Generation:          1
  Resource Version:    15618006
  Self Link:           /apis/flagger.app/v1beta1/namespaces/microservices-demo/canaries/frontend
  UID:                 04d6c41b-90a0-493b-8af7-edfad4b6f292
Spec:
  Analysis:
    Interval:    30s
    Max Weight:  30
    Metrics:
      Interval:               30s
      Name:                   request-success-rate
      Threshold:              99
    Step Weight:              5
    Threshold:                5
  Progress Deadline Seconds:  60
  Provider:                   istio
  Service:
    Gateways:
      frontend-gateway
    Hosts:
      *
    Port:         80
    Target Port:  8080
    Traffic Policy:
      Tls:
        Mode:  DISABLE
  Target Ref:
    API Version:  apps/v1
    Kind:         Deployment
    Name:         frontend
Status:
  Canary Weight:  0
  Conditions:
    Last Transition Time:  2021-03-06T17:38:20Z
    Last Update Time:      2021-03-06T17:38:20Z
    Message:               Canary analysis completed successfully, promotion finished.
    Reason:                Succeeded
    Status:                True
    Type:                  Promoted
  Failed Checks:           0
  Iterations:              0
  Last Applied Spec:       85cdf99c8b
  Last Transition Time:    2021-03-06T17:38:20Z
  Phase:                   Succeeded
  Tracked Configs:
Events:
  Type    Reason  Age                   From     Message
  ----    ------  ----                  ----     -------
  Normal  Synced  6m35s                 flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal  Synced  6m5s                  flagger  Starting canary analysis for frontend.microservices-demo
  Normal  Synced  6m5s                  flagger  Advance frontend.microservices-demo canary weight 5
  Normal  Synced  5m35s                 flagger  Advance frontend.microservices-demo canary weight 10
  Normal  Synced  5m5s                  flagger  Advance frontend.microservices-demo canary weight 15
  Normal  Synced  4m35s                 flagger  Advance frontend.microservices-demo canary weight 20
  Normal  Synced  4m5s                  flagger  Advance frontend.microservices-demo canary weight 25
  Normal  Synced  3m35s                 flagger  Advance frontend.microservices-demo canary weight 30
  Normal  Synced  3m5s                  flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal  Synced  2m5s (x2 over 2m35s)  flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
~~~

в соответствии с настройками канарейки:
    interval: 30s
    threshold: 5
    maxWeight: 30

График из прометея с метриками, который пришли вместе с Flagger: ![flagger_canary_status](kubernetes-gitops/flagger_canary_status.png)

  Вывод:
  
  метрика, которую я так и не нашла в прометее и с которой работает канарейка скорее всего смерженная метрика Istio и приложения.						
  "Envoy sidecar will merge Istio’s metrics with the application metrics. The merged metrics will be scraped from /stats/prometheus:15020" 

  [metrics-merging](https://istio.io/latest/docs/ops/integrations/prometheus/#option-1-metrics-merging)


</details> 

<details>
  <summary>## Домашняя работа 11</summary>

## CSI. Обзор подсистем хранения данных в Kubernetes

1) Создать StorageClass для CSI Host Path Driver

Сделали это в миникубе (https://minikube.sigs.k8s.io/docs/tutorials/volume_snapshots_and_csi/)

- установлена версия 1.18.1 миникуба (https://github.com/kubernetes/minikube/releases)

~~~sh
$ minikube version
minikube version: v1.18.1
commit: 09ee84d530de4a92f00f1c5dbc34cead092b95bc
~~~
	
2) Устанавливаем csi-hostpath-driver

~~~sh
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path
~~~

По csi-driver-host-path/docs/deploy-1.17-and-later.md устанавлмваем csi-hostpath-driver

~~~sh
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
csi-hostpath-attacher-0      1/1     Running   0          11h
csi-hostpath-provisioner-0   1/1     Running   0          11h
csi-hostpath-resizer-0       1/1     Running   0          11h
csi-hostpath-snapshotter-0   1/1     Running   0          11h
csi-hostpath-socat-0         1/1     Running   0          11h
csi-hostpathplugin-0         5/5     Running   0          11h
snapshot-controller-0        1/1     Running   0          11h
~~~

4) Создаем storage class csi-hostpath-sc:

~~~sh
$ kubectl get sc
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-sc      hostpath.csi.k8s.io        Delete          Immediate           true                   10h
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  167d
~~~

5) Создаем pvc csi-hostpath-sc. Вместе с ней создается и pv

~~~sh 
$ kubectl get pvc
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
csi-pvc   Bound    pvc-38f69cca-eeeb-44e9-8400-6363a016306d   1Gi        RWO            csi-hostpath-sc   10h

$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS      REASON   AGE
pvc-38f69cca-eeeb-44e9-8400-6363a016306d   1Gi        RWO            Delete           Bound    default/csi-pvc   csi-hostpath-sc            10h

$ kubectl describe pvc csi-pvc
Name:          csi-pvc
Namespace:     default
StorageClass:  csi-hostpath-sc
Status:        Terminating (lasts 14h)
Volume:        pvc-38f69cca-eeeb-44e9-8400-6363a016306d
Labels:        <none>
Annotations:   kubectl.kubernetes.io/last-applied-configuration:
                 {"apiVersion":"v1","kind":"PersistentVolumeClaim","metadata":{"annotations":{},"name":"csi-pvc","namespace":"default"},"spec":{"accessMode...
               pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: hostpath.csi.k8s.io
Finalizers:    [snapshot.storage.kubernetes.io/pvc-as-source-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Mounted By:    <none>
Events:        <none>

~~~

6) Создаем под my-csi-app, заходим в него и создаем файлик /data/hello-world: 

~~~sh
kubectl exec -it my-csi-app /bin/sh
/ # touch /data/hello-world
/ # exit

$ kubectl exec -it $(kubectl get pods --selector app=csi-hostpathplugin -o jsonpath='{.items[*].metadata.name}') -c hostpath /bin/sh
/ # find / -name hello-world
/var/lib/kubelet/pods/2b7ee9f3-ef3a-49a2-9e24-e613a0e956a7/volumes/kubernetes.io~csi/pvc-38f69cca-eeeb-44e9-8400-6363a016306d/mount/hello-world
/csi-data-dir/346fc9a1-80c0-11eb-89fe-0242ac11000b/hello-world
/ # exit

~~~

7) Создаем snapshot c pvc:

~~~sh

$ kubectl apply -f csi-snapshot-v1beta1.yaml
volumesnapshot.snapshot.storage.k8s.io/new-snapshot-demo created

$ kubectl describe volumesnapshot.snapshot.storage.k8s.io new-snapshot-demo
Name:         new-snapshot-demo
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"snapshot.storage.k8s.io/v1beta1","kind":"VolumeSnapshot","metadata":{"annotations":{},"name":"new-snapshot-demo","namespace...
API Version:  snapshot.storage.k8s.io/v1beta1
Kind:         VolumeSnapshot
Metadata:
  Creation Timestamp:  2021-03-13T12:51:15Z
  Finalizers:
    snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection
    snapshot.storage.kubernetes.io/volumesnapshot-bound-protection
  Generation:  1
  Managed Fields:
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
      f:spec:
        .:
        f:source:
          .:
          f:persistentVolumeClaimName:
        f:volumeSnapshotClassName:
    Manager:      kubectl
    Operation:    Update
    Time:         2021-03-13T12:51:15Z
    API Version:  snapshot.storage.k8s.io/v1beta1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:finalizers:
          .:
          v:"snapshot.storage.kubernetes.io/volumesnapshot-as-source-protection":
          v:"snapshot.storage.kubernetes.io/volumesnapshot-bound-protection":
      f:status:
        .:
        f:boundVolumeSnapshotContentName:
        f:creationTime:
        f:readyToUse:
        f:restoreSize:
    Manager:         snapshot-controller
    Operation:       Update
    Time:            2021-03-13T12:51:16Z
  Resource Version:  3021082
  UID:               2fff78c2-0dcc-42a5-9422-db3d1ecd8f10
Spec:
  Source:
    Persistent Volume Claim Name:  csi-pvc
  Volume Snapshot Class Name:      csi-hostpath-snapclass
Status:
  Bound Volume Snapshot Content Name:  snapcontent-2fff78c2-0dcc-42a5-9422-db3d1ecd8f10
  Creation Time:                       2021-03-13T12:51:15Z
  Ready To Use:                        true
  Restore Size:                        1Gi
Events:                                <none>

$ kubectl get VolumeSnapshotClass
NAME                     AGE
csi-hostpath-snapclass   10h

$ kubectl get volumesnapshot
NAME                AGE
new-snapshot-demo   8m47s
~~~

#Здесь важно:

Ready To Use:                        true

Если false, то из такого snapshot не восстановиться.


8) Удаляем pvc csi-pvc: 

~~~ sh
$ kubectl delete pod my-csi-app
pod "my-csi-app" deleted
$ kubectl edit pvc csi-pvc
persistentvolumeclaim/csi-pvc edited
$ kubectl delete pvc csi-pvc
persistentvolumeclaim "csi-pvc" deleted
$ kubectl get pvc
No resources found.
$ kubectl get pv
No resources found.
~~~
# Удалить удалось только после edit и удаления всех finalizers.
 
9) Создаем pvs из snapshot:

~~~sh
[itokareva@otus examples]$ kubectl apply -f csi-restore.yaml
persistentvolumeclaim/csi-pvc created
~~~  

10) поднимаем под: 

~~~sh
$ kubectl apply -f csi-app.yaml
pod/my-csi-app created
~~~

11) Проверяем, что файлик присутствует:

~~~sh
 kubectl exec -it my-csi-app /bin/sh
/ # ls /data/
hello-world
/ # exit
~~~
</details>
 

<details>
  <summary>## Домашняя работа 12</summary>

## Отладка и тестирование в kubernetes

## kubectl debug

1) Установили в наш кластер (minikube) kubectl debug

~~~sh
wget https://github.com/aylei/kubectl-debug/releases/download/v0.1.1/kubectl-debug_0.1.1_linux_amd64.tar.gz
tar -zxvf kubectl-debug.tar.gz kubectl-debug
sudo mv kubectl-debug /usr/local/bin/
kubectl apply -f https://raw.githubusercontent.com/aylei/kubectl-debug/master/scripts/agent_daemonset.yml

$ kubectl debug --agentless=false frontend
error execute remote, Internal error occurred: error attaching to container: Error: No such image: nicolaka/netshoot:latest
error: Internal error occurred: error attaching to container: Error: No such image: nicolaka/netshoot:latest
~~~
Полечилось:
      containers:
        - name: debug-agent
          image: aylei/debug-agent:v0.1.1

вместо image: aylei/debug-agent:latest

2) Запустили в кластере поды с агентом kubectl-debug

~~~sh
$ kubectl debug --agentless=false frontend
pulling image nicolaka/netshoot:latest...
latest: Pulling from nicolaka/netshoot
4c0d98bf9879: Pull complete
df962687d630: Pull complete
f4b598a64a46: Pull complete
a3f487e8dfcb: Pull complete
0d084d29b530: Pull complete
c40275cdc1a4: Pull complete
53d8247f861d: Pull complete
Digest: sha256:6ae5a524ab390824a43a29a8a2ec7b9c013736d98a0aed264f1132196098aac2
Status: Downloaded newer image for nicolaka/netshoot:latest
starting debug container...
container created, open tty...
bash-5.1#  ps aux
PID   USER     TIME  COMMAND
    1 root      0:58 /frontend/server
   14 root      0:00 bash
   20 root      0:00 ps aux

bash-5.1# strace -p1
strace: Process 1 attached
futex(0xf98d68, FUTEX_WAIT_PRIVATE, 0, NULL) = 0
futex(0xf98d68, FUTEX_WAIT_PRIVATE, 0, NULL) = 0
futex(0xf98d68, FUTEX_WAIT_PRIVATE, 0, NULL) = 0
epoll_pwait(3, [], 128, 0, NULL, 1126072540297173) = 0
futex(0xf98d68, FUTEX_WAIT_PRIVATE, 0, NULL) = -1 EAGAIN (Resource temporarily unavailable)
write(5, "\0", 1)                       = 1
futex(0xf98d68, FUTEX_WAIT_PRIVATE, 0, NULL) = 0
epoll_pwait(3, [], 128, 0, NULL, 1126074073158758) = 0
epoll_pwait(3, [], 128, 0, NULL, 1126074073319238) = 0
socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 7
setsockopt(7, SOL_SOCKET, SO_BROADCAST, [1], 4) = 0
connect(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("10.96.0.10")}, 16) = 0
epoll_ctl(3, EPOLL_CTL_ADD, 7, {EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET, {u32=1375927552, u64=140713094479104}}) = 0
getsockname(7, {sa_family=AF_INET, sin_port=htons(60932), sin_addr=inet_addr("172.17.0.5")}, [112->16]) = 0
getpeername(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("10.96.0.10")}, [112->16]) = 0
--- SIGURG {si_signo=SIGURG, si_code=SI_TKILL, si_pid=1, si_uid=0} ---
rt_sigreturn({mask=[]})                 = 0
write(7, "\247\27\1\0\0\1\0\0\0\0\0\0\tlocalhost\7default\3s"..., 53) = 53
read(7, "\247\27\205\3\0\1\0\0\0\1\0\0\tlocalhost\7default\3s"..., 512) = 146
epoll_ctl(3, EPOLL_CTL_DEL, 7, 0xc00013c9fc) = 0
........

bash-5.1# cat trace-1.txt
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 29.08    0.002886         192        15           rt_sigreturn
 20.33    0.002018         183        11           futex
 14.17    0.001406         200         7           epoll_ctl
  6.78    0.000673         168         4           getpeername
  6.12    0.000607         151         4           write
  5.52    0.000548         137         4           getsockname
  4.72    0.000468         117         4           setsockopt
  4.32    0.000429         107         4         1 read
  3.90    0.000387          96         4           socket
  2.56    0.000254          63         4           connect
  2.50    0.000248          82         3           close
  0.00    0.000000           0         1           newfstatat
------ ----------- ----------- --------- --------- ----------------
100.00    0.009924         152        65         1 total

--------v0.1.1 kubectl-debug/pkg/agent/runtime.go

hostConfig := &container.HostConfig{
		NetworkMode: container.NetworkMode(m.containerMode(targetId)),
		UsernsMode:  container.UsernsMode(m.containerMode(targetId)),
		IpcMode:     container.IpcMode(m.containerMode(targetId)),
		PidMode:     container.PidMode(m.containerMode(targetId)),
		CapAdd:      strslice.StrSlice([]string{"SYS_PTRACE", "SYS_ADMIN"}),
--------v0.1.0 kubectl-debug/pkg/agent/runtime.go
	hostConfig := &container.HostConfig{
		NetworkMode: container.NetworkMode(m.containerMode(targetId)),
		UsernsMode:  container.UsernsMode(m.containerMode(targetId)),
		IpcMode:     container.IpcMode(m.containerMode(targetId)),
		PidMode:     container.PidMode(m.containerMode(targetId)),
	}
~~~

Резюме:
strace работает без ошибок в версии debug-agent:v0.1.1. В этой версии привилегии уже добавлены.


# iptables-tailer

1) Поднят кластер с установленным и запущенным Calico (для GKE - это просто
включенные галки Network Policy) скрипт terraform в каталоге kubernetes-debug/kit/infra

2) Для нашего задания в качестве тестового приложения вы возьмем [netperf-operator](https://github.com/piontec/netperf-operator)
Это Kubernetes-оператор, который позволяет запускать тесты пропускной
способности сети между нодами кластера.

3) Запустить наш первый тест, применив манифест kubernetes-debug/kit/cr.yaml.

~~~sh
$ kubectl get netperfs.app.example.com
NAME      AGE
example   7s
kubectl describe netperfs.app.example.com example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"app.example.com/v1alpha1","kind":"Netperf","metadata":{"annotations":{},"name":"example","namespace":"default"}}
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2021-03-21T09:56:39Z
  Generation:          4
  Managed Fields:
    API Version:  app.example.com/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
    Manager:      kubectl
    Operation:    Update
    Time:         2021-03-21T09:56:39Z
    API Version:  app.example.com/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:clientNode:
        f:serverNode:
      f:status:
        .:
        f:clientPod:
        f:serverPod:
        f:speedBitsPerSec:
        f:status:
    Manager:         netperf-operator
    Operation:       Update
    Time:            2021-03-21T09:56:56Z
  Resource Version:  994239
  Self Link:         /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:               bfdb369c-241d-4b9b-87f6-57966a7c1768
Spec:
  Client Node:
  Server Node:
Status:
  Client Pod:          netperf-client-57966a7c1768
  Server Pod:          netperf-server-57966a7c1768
  Speed Bits Per Sec:  6953.09
  Status:              Done
Events:                <none>
~~~

Видим, что Status: Done и выполнен замер Speed Bits Per Sec:  6953.09.

4) Теперь можно добавить сетевую политику для Calico, чтобы ограничить
доступ к подам Netperf и включить логирование в iptables.

После примененния kubernetes-debug/kit/NetworkPolicy.yaml и повторного запуска теста:

~~~sh
$ kubectl apply -f NetworkPolicy.yaml
networkpolicy.crd.projectcalico.org/netperf-calico-policy created
$ kubectl get networkpolicies.crd.projectcalico.org
NAME                    AGE
netperf-calico-policy   2m44s
$ kubectl delete -f cr.yaml
netperf.app.example.com "example" deleted
$ kubectl apply -f cr.yaml
netperf.app.example.com/example created
~~~ 
Видим, что что тест висит в состоянии Starting:

~~~sh
$ kubectl describe netperfs.app.example.com example
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"app.example.com/v1alpha1","kind":"Netperf","metadata":{"annotations":{},"name":"example","namespace":"default"}}
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2021-03-21T10:31:00Z
  Generation:          3
  Managed Fields:
    API Version:  app.example.com/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .:
          f:kubectl.kubernetes.io/last-applied-configuration:
    Manager:      kubectl
    Operation:    Update
    Time:         2021-03-21T10:31:00Z
    API Version:  app.example.com/v1alpha1
    Fields Type:  FieldsV1
    fieldsV1:
      f:spec:
        .:
        f:clientNode:
        f:serverNode:
      f:status:
        .:
        f:clientPod:
        f:serverPod:
        f:speedBitsPerSec:
        f:status:
    Manager:         netperf-operator
    Operation:       Update
    Time:            2021-03-21T10:31:04Z
  Resource Version:  1006227
  Self Link:         /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:               765c342a-c269-4943-a2da-f30797dc4706
Spec:
  Client Node:
  Server Node:
Status:
  Client Pod:          netperf-client-f30797dc4706
  Server Pod:          netperf-server-f30797dc4706
  Speed Bits Per Sec:  0
  Status:              Started test
Events:                <none>
~~~

5) Подключились к ноде по ssh и увидели, что в логах ноды Kubernetes появились сообщения об
отброшенных пакетах:
 
~~~sh
itokareva@gke-omega-omega-pool-3b6acd66-zcxt:~$ sudo iptables --list -nv | grep DROP -
Chain FORWARD (policy DROP 0 packets, 0 bytes)
    0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes firewall for dropping marked packets */ mark match 0x8000/0x8000
    0     0 DROP       all  --  *      *      !127.0.0.0/8          127.0.0.0/8          /* block incoming localnet connections */ ! ctstate RELATED,ESTABLISHED,DNAT
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate INVALID
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:PEii4MWZaiLl4U3f */ /* Unknown interface */
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:gIg8o9izBG4yW7xT */ /* Unknown interface */
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:DhCx6XlDBaVSw7oj */ /* Unknown interface */
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:6KGofkZJk0yyBq5d */ /* Unknown interface */
    0     0 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:D-EomQ5TN6h3wFbe */ ctstate INVALID
    0     0 DROP       udp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:qWYggV8CI8QaTKjo */ /* Drop VXLAN encapped packets originating in pods */ multiport dports 4789
.....

$ kubectl logs kube-iptables-tailer-xbnmd -n kube-system
2021/03/21 11:07:10 Invalid value for METRICS_SERVER_PORT: using default: 9090
E0321 11:07:15.072035       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
E0321 11:07:20.071485       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
E0321 11:07:25.071548       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
E0321 11:07:30.071457       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
E0321 11:07:35.071564       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
E0321 11:07:40.071494       1 watcher.go:36] Failed to open file: name=/var/log/iptables.log, error=open /var/log/iptables.log: no such file or directory
~~~

6) Установим и запустим iptables-tailer, применив kubernetes-debug/kit/daemonset.yaml.
Были большие мучения с переменной среды "IPTABLES_LOG_PATH". Дело в том, что во многих современных Linux-дистрибутивах логи по умолчанию не
пишутся в /var/log/iptables.log. Не пишутся они ни в /var/log/kern.log, ни в /var/log/messages.log. 
Они пишутся в журнал systemd: /var/log/journal. Этот путь задали в переменной JOURNAL_DIRECTORY.
Но наш iptables-tailer не может читать такой формат лога. 
Требуется пересобрать образ включив опцию C-Go.

~~~sh
$ git clone git@github.com:box/kube-iptables-tailer.git
$ cd <path-to-the-source-code>
$ make container-cgo  
~~~

7) Events появились. Теперь можно дебадить не заходя по ssh на нашу ноду:

~~~sh
$ kubectl describe pod --selector=app=netperf-operator
Name:           netperf-client-3197fafa5e82
Namespace:      default
<<skipped>>
Events:
  Type     Reason      Age                    From                                         Message
  ----     ------      ----                   ----                                         -------
  Normal   Scheduled   6m56s                  default-scheduler                            Successfully assigned default/netperf-client-3197fafa5e82 to gke-omega-omega-pool-3b6acd66-zcxt
  Normal   Pulled      2m19s (x3 over 6m55s)  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal   Created     2m18s (x3 over 6m55s)  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Created container netperf-client-3197fafa5e82
  Normal   Started     2m18s (x3 over 6m55s)  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Started container netperf-client-3197fafa5e82
  Warning  PacketDrop  2m18s (x2 over 4m44s)  kube-iptables-tailer                         Packet dropped when sending traffic to netperf-server-3197fafa5e82 (10.108.2.23)
  Warning  BackOff     8s (x2 over 2m34s)     kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Back-off restarting failed container

Name:           netperf-server-3197fafa5e82
Namespace:      default
<<skipped>>
Events:
  Type     Reason      Age                    From                                         Message
  ----     ------      ----                   ----                                         -------
  Normal   Scheduled   6m58s                  default-scheduler                            Successfully assigned default/netperf-server-3197fafa5e82 to gke-omega-omega-pool-3b6acd66-zcxt
  Normal   Pulled      6m57s                  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal   Created     6m57s                  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Created container netperf-server-3197fafa5e82
  Normal   Started     6m57s                  kubelet, gke-omega-omega-pool-3b6acd66-zcxt  Started container netperf-server-3197fafa5e82
  Warning  PacketDrop  6m55s                  kube-iptables-tailer                         Packet dropped when receiving traffic from 10.108.2.24
  Warning  PacketDrop  2m18s (x2 over 4m44s)  kube-iptables-tailer                         Packet dropped when receiving traffic from netperf-client-3197fafa5e82 (10.108.2.24)
~~~

Задание со *
чтобы в логах отображались имена Podов, а не их IP-адреса выставим переменную:

- name: "POD_IDENTIFIER"
  value: "name_with_namespace"

Исправьте ошибку в нашей сетевой политике, чтобы Netperf снова начал работать:

~~~sh
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: netperf-calico-policy
  labels:
spec:
  order: 10
  selector: app == "netperf-operator"
  ingress:
    - action: Allow
      source:
        selector: netperf-role == "netperf-client"
    - action: Log
    - action: Allow
  egress:
    - action: Allow
      destination:
        selector: netperf-role == "netperf-client
    - action: Log
    - action: Deny
~~~

</details>

<details>
  <summary>## Домашняя работа 13</summary>

## Подходы к развертыванию и обновлению production-grade кластера

1) Подготовка машин:

- Готовим образ с предустановленными tools c помощью packer: kubernetes-production/packer/vm_and_tools.json

- Развертываем 4 виртуальные машины с запеченным образом kubernetes-production/terraform_baked_vm

2) Создание кластера


-  Развертываем кластер версии 1.17.4-00 на четырех виртуальных машинах вручную:


<details>
  <summary>## kubeadm init на master-node</summary>
	
~~~sh
$ sudo kubeadm init --pod-network-cidr=192.168.0.0/24
I0508 21:15:12.332221    2380 version.go:251] remote version is much newer: v1.21.0; falling back to: stable-1.17
W0508 21:15:12.631664    2380 validation.go:28] Cannot validate kubelet config - no validator is available
W0508 21:15:12.631691    2380 validation.go:28] Cannot validate kube-proxy config - no validator is available
[init] Using Kubernetes version: v1.17.17
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-node-0 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.166.15.193]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-node-0 localhost] and IPs [10.166.15.193 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-node-0 localhost] and IPs [10.166.15.193 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
W0508 21:15:38.579806    2380 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[control-plane] Creating static Pod manifest for "kube-scheduler"
W0508 21:15:38.581275    2380 manifests.go:214] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 18.503319 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.17" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-node-0 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node k8s-node-0 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: l0jgej.z1ubdfj8757dc4c3
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.166.15.193:6443 --token l0jgej.z1ubdfj8757dc4c3 \
    --discovery-token-ca-cert-hash sha256:cafe2cd486f29221b53ff901f70333ab5f4962787aad93e571e6446966564236
~~~

</details>

Присоединяем worker-ноду:

~~~sh
$ sudo kubeadm join 10.166.15.193:6443 --token l0jgej.z1ubdfj8757dc4c3     --discovery-token-ca-cert-hash sha256:cafe2cd486f29221b53ff901f70333ab5f4962787aad93e571e6446966564236
W0508 21:52:24.664280   10033 join.go:346] [preflight] WARNING: JoinControlPane.controlPlane settings will be ignored when control-plane flag is not set.
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.17" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
~~~

-  Автоматизируем развертывание с помощью terraform. Разворачиваем 4 виртуальные машины (1 - master, 3 - workers) и на выходе получаем k8-cluster.
-  Все скрипты в kubernetes-production/terraform_master_worker

<details>
  <summary>## terraform отработал. Проверяем количество запущенных нод </summary>
	
~~~sh
Apply complete! Resources: 3 added, 0 changed, 3 destroyed.

Outputs:

inventory = { "_meta": {
        "hostvars": {
               "k8s-worker-0": {
             "host_name": "k8s-worker-0",
             "host_ext_ip": "35.228.212.66"
           },
               "k8s-worker-1": {
             "host_name": "k8s-worker-1",
             "host_ext_ip": "35.228.7.247"
           },
               "k8s-worker-2": {
             "host_name": "k8s-worker-2",
             "host_ext_ip": "35.228.10.168"
           },
                 "host_name": "k8s-master",
             "host_ext_ip": "35.228.80.91"
        }

    },
  "docker-host": {
    "hosts": [
       "k8s-worker-0","k8s-worker-1","k8s-worker-2","k8s-master"
              ]
  }

}
$ ssh 35.228.80.91
Welcome to Ubuntu 18.04.5 LTS (GNU/Linux 5.4.0-1042-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Wed May 12 00:44:15 UTC 2021

  System load:  0.14               Users logged in:        0
  Usage of /:   23.4% of 19.21GB   IP address for ens4:    10.166.0.11
  Memory usage: 14%                IP address for docker0: 172.17.0.1
  Swap usage:   0%                 IP address for tunl0:   192.168.0.192
  Processes:    163

 * Pure upstream Kubernetes 1.21, smallest, simplest cluster ops!

     https://microk8s.io/

3 updates can be applied immediately.
To see these additional updates run: apt list --upgradable

New release '20.04.2 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


*** System restart required ***
Last login: Wed May 12 00:18:05 2021 from 5.144.116.254
itokareva@k8s-master:~$ kubectl get nodes
NAME           STATUS   ROLES    AGE   VERSION
k8s-master     Ready    master   25m   v1.17.4
k8s-worker-0   Ready    <none>   20m   v1.17.4
k8s-worker-1   Ready    <none>   20m   v1.17.4
k8s-worker-2   Ready    <none>   20m   v1.17.4
~~~
</details>

3) Обновление кластера

-  Обновляем созданный кластер до версии 1.18.0-00 так же с помощью terraform. 
-  Скрипты в каталоге kubernetes-production/terraform_upgrade

Для обновления запускаем:

~~~sh
terraform apply -auto-approve
~~~

Данный запуск делаем для каждой worker-ноды, предварительно задавая имя  worker-ноды (здесь - k8s-worker-2) в main_upgrade.tf:

~~~sh 
data "google_compute_instance" "k8s-onega" {
 name = "k8s-worker-2"

}
~~~

По-хорошему надо бы зашить в переменную.

<details>
  <summary>## upgrade последней ноды (второй). Проверяем количество запущенных нод </summary>
	
~~~sh
$ terraform apply -auto-approve
data.google_compute_instance.k8s-ladoga: Refreshing state...
data.google_compute_instance.k8s-onega: Refreshing state...
null_resource.k8s-master-upgrade: Refreshing state... [id=1484611468627528473]
null_resource.k8s-worker-0-upgrade: Refreshing state... [id=3169972396813765732]
null_resource.k8s-worker-0-upgrade: Destroying... [id=3169972396813765732]
null_resource.k8s-worker-0-upgrade: Destruction complete after 0s
null_resource.k8s-worker-0-upgrade: Creating...
null_resource.k8s-worker-0-upgrade: Provisioning with 'remote-exec'...
null_resource.k8s-worker-0-upgrade (remote-exec): Connecting to remote host via SSH...
null_resource.k8s-worker-0-upgrade (remote-exec):   Host: 35.228.80.91
null_resource.k8s-worker-0-upgrade (remote-exec):   User: itokareva
null_resource.k8s-worker-0-upgrade (remote-exec):   Password: false
null_resource.k8s-worker-0-upgrade (remote-exec):   Private key: true
null_resource.k8s-worker-0-upgrade (remote-exec):   Certificate: false
null_resource.k8s-worker-0-upgrade (remote-exec):   SSH Agent: false
null_resource.k8s-worker-0-upgrade (remote-exec):   Checking Host Key: false
null_resource.k8s-worker-0-upgrade (remote-exec): Connected!
null_resource.k8s-worker-0-upgrade (remote-exec): Reading package lists... 0%
null_resource.k8s-worker-0-upgrade (remote-exec): Reading package lists... 100%
null_resource.k8s-worker-0-upgrade (remote-exec): Reading package lists... Done
null_resource.k8s-worker-0-upgrade (remote-exec): Building dependency tree... 0%
null_resource.k8s-worker-0-upgrade (remote-exec): Building dependency tree... 0%
null_resource.k8s-worker-0-upgrade (remote-exec): Building dependency tree... 50%
null_resource.k8s-worker-0-upgrade (remote-exec): Building dependency tree... 50%
null_resource.k8s-worker-0-upgrade (remote-exec): Building dependency tree
null_resource.k8s-worker-0-upgrade (remote-exec): Reading state information... 0%
null_resource.k8s-worker-0-upgrade (remote-exec): Reading state information... 0%
null_resource.k8s-worker-0-upgrade (remote-exec): Reading state information... Done
null_resource.k8s-worker-0-upgrade (remote-exec): kubeadm is already the newest version (1.18.0-00).
null_resource.k8s-worker-0-upgrade (remote-exec): kubelet is already the newest version (1.18.0-00).
null_resource.k8s-worker-0-upgrade (remote-exec): The following package was automatically installed and is no longer required:
null_resource.k8s-worker-0-upgrade (remote-exec):   libnuma1
null_resource.k8s-worker-0-upgrade (remote-exec): Use 'sudo apt autoremove' to remove it.
null_resource.k8s-worker-0-upgrade (remote-exec): 0 upgraded, 0 newly installed, 0 to remove and 2 not upgraded.
null_resource.k8s-worker-0-upgrade (remote-exec): kubeadm version: &version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.0", GitCommit:"9e991415386e4cf155a24b1da15becaa390438d8", GitTreeState:"clean", BuildDate:"2020-03-25T14:56:30Z", GoVersion:"go1.13.8", Compiler:"gc", Platform:"linux/amd64"}
null_resource.k8s-worker-0-upgrade (remote-exec): Kubernetes v1.18.0
null_resource.k8s-worker-0-upgrade: Creation complete after 2s [id=4029035116811033115]
null_resource.k8s-master-uncordon: Creating...
null_resource.k8s-master-uncordon: Provisioning with 'remote-exec'...
null_resource.k8s-master-uncordon (remote-exec): Connecting to remote host via SSH...
null_resource.k8s-master-uncordon (remote-exec):   Host: 35.228.212.66
null_resource.k8s-master-uncordon (remote-exec):   User: itokareva
null_resource.k8s-master-uncordon (remote-exec):   Password: false
null_resource.k8s-master-uncordon (remote-exec):   Private key: true
null_resource.k8s-master-uncordon (remote-exec):   Certificate: false
null_resource.k8s-master-uncordon (remote-exec):   SSH Agent: false
null_resource.k8s-master-uncordon (remote-exec):   Checking Host Key: false
null_resource.k8s-master-uncordon (remote-exec): Connected!
null_resource.k8s-master-uncordon (remote-exec): Error: unknown flag: --ignore-daemonsets
null_resource.k8s-master-uncordon (remote-exec): See 'kubectl uncordon --help' for usage.
null_resource.k8s-master-uncordon (remote-exec): NAME           STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
null_resource.k8s-master-uncordon (remote-exec): k8s-master     Ready    master   34m   v1.18.0   10.166.0.21   <none>        Ubuntu 18.04.5 LTS   5.4.0-1042-gcp   docker://19.3.8
null_resource.k8s-master-uncordon (remote-exec): k8s-worker-0   Ready    <none>   33m   v1.18.0   10.166.0.28   <none>        Ubuntu 18.04.5 LTS   5.4.0-1042-gcp   docker://19.3.8
null_resource.k8s-master-uncordon (remote-exec): k8s-worker-1   Ready    <none>   33m   v1.18.0   10.166.0.22   <none>        Ubuntu 18.04.5 LTS   5.4.0-1042-gcp   docker://19.3.8
null_resource.k8s-master-uncordon (remote-exec): k8s-worker-2   Ready    <none>   33m   v1.18.0   10.166.0.27   <none>        Ubuntu 18.04.5 LTS   5.4.0-1042-gcp   docker://19.3.8
null_resource.k8s-master-uncordon: Creation complete after 1s [id=6135758193408990531]
~~~	

</details>

4) Автоматическое развертывание кластера с помощью kubespray

Kubespray - это Ansible playbook для установки Kubernetes.
Для его использования достаточно иметь SSH-доступ на машины, поэтому не важно как они были созданы (Cloud, Bare metal).

-  поднимаем 6 виртуальных машин с помощью terraform c образами ubuntu-1804-lts (kubernetes-production/terraform_vm)
-  конфигурируем inventory для ansible-playbook (inventory/mycluster/inventory.ini)
-  запускаем ansible-playbook
~~~sh
$ ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root --user=itokareva --key-file=~/.ssh/id_rsa cluster.yml   
~~~   
- дожидаемся, когда playbook отработает

- захоим на master-ноду и проверяем количество развернутых нод:

~~~sh
k8s-node-0                 : ok=533  changed=56   unreachable=0    failed=0    skipped=1161 rescued=0    ignored=2
k8s-node-1                 : ok=467  changed=47   unreachable=0    failed=0    skipped=1012 rescued=0    ignored=1
k8s-node-2                 : ok=469  changed=48   unreachable=0    failed=0    skipped=1010 rescued=0    ignored=1
k8s-node-3                 : ok=347  changed=38   unreachable=0    failed=0    skipped=631  rescued=0    ignored=1
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Saturday 15 May 2021  18:58:34 +0300 (0:00:00.160)       0:09:50.182 **********
===============================================================================
kubernetes/control-plane : Joining control plane node to the cluster. --------------------------------------------------------------------------------------------------------------- 31.43s
kubernetes/kubeadm : Join to cluster ------------------------------------------------------------------------------------------------------------------------------------------------ 25.13s
kubernetes/control-plane : kubeadm | Initialize first master ------------------------------------------------------------------------------------------------------------------------ 16.48s
Gen_certs | Write etcd member and admin certs to other etcd nodes -------------------------------------------------------------------------------------------------------------------- 9.74s
Gen_certs | Write etcd member and admin certs to other etcd nodes -------------------------------------------------------------------------------------------------------------------- 9.70s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS Template ---------------------------------------------------------------------------------------------------------------- 7.70s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources -------------------------------------------------------------------------------------------------------------------------- 7.24s
download | Download files / images --------------------------------------------------------------------------------------------------------------------------------------------------- 6.41s
Gen_certs | Write node certs to other etcd nodes ------------------------------------------------------------------------------------------------------------------------------------- 5.96s
Gen_certs | Write node certs to other etcd nodes ------------------------------------------------------------------------------------------------------------------------------------- 5.75s
Gen_certs | Gather etcd member and admin certs from first etcd node ------------------------------------------------------------------------------------------------------------------ 4.84s
network_plugin/calico : Calico | Create calico manifests ----------------------------------------------------------------------------------------------------------------------------- 4.80s
Gen_certs | Gather etcd member and admin certs from first etcd node ------------------------------------------------------------------------------------------------------------------ 4.78s
download_file | Download item -------------------------------------------------------------------------------------------------------------------------------------------------------- 4.47s
network_plugin/calico : Start Calico resources --------------------------------------------------------------------------------------------------------------------------------------- 4.47s
kubernetes/preinstall : Get current calico cluster version --------------------------------------------------------------------------------------------------------------------------- 4.13s
container-engine/docker : ensure docker packages are installed ----------------------------------------------------------------------------------------------------------------------- 3.98s
download | Download files / images --------------------------------------------------------------------------------------------------------------------------------------------------- 3.68s
download | Download files / images --------------------------------------------------------------------------------------------------------------------------------------------------- 3.53s
download | Download files / images --------------------------------------------------------------------------------------------------------------------------------------------------- 3.50s
$ ssh 35.228.85.69
$ mkdir -p $HOME/.kube
itokareva@k8s-node-0:~$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
itokareva@k8s-node-0:~$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
itokareva@k8s-node-0:~$ kubectl get nodes
NAME         STATUS   ROLES                  AGE   VERSION
k8s-node-0   Ready    control-plane,master   17m   v1.20.7
k8s-node-1   Ready    control-plane,master   16m   v1.20.7
k8s-node-2   Ready    control-plane,master   16m   v1.20.7
k8s-node-3   Ready    <none>                 15m   v1.20.7
~~~

Задание со (*)

Выполните установку кластера с 3 master-нодами и 2 worker-нодами.

- [x] выполнено в п.4, с единственной поправкой - worker-нода - одна. Пробовала с двумя и тремя - завершалось с ошибкой.

</details>
