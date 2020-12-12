# itokareva_platform
itokareva Platform repository

# Домашняя работа 1
Настройка локального Настройка локального окружения. Запуск окружения. 
Запуск первого контейнера. первого контейнера. Работа с kubectl 

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
  
   Задание: Разберитесь почему все pod в namespace kube-system восстановились после удаления. 

   core-dns - восстанавливается, потому что kubernetes works in a declarative manner, which means we declare what the desired state should 
   be and kubernetes manages it for us. Control-manager is the component which is responsible for keeping track and maintaining the 
   required state by interacting with api-server and various controllers. So, it can also be treated as the interacting medium between 
   various controllers and api-server.
   
   kube-apiserver - желаемое состояние хранится в etcd и поддерживается на уровне ОС(?). Не нашла исчерпывающей информации

# Домашняя работа 2

  Kubernetes controllers. Kubernetes controllers. ReplicaSet, Deployment, ReplicaSet, Deployment, DaemonSet 

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

