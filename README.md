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
