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

 ![nginx-dashboard](kubernetes-monitoring/nginx_connections.png

</details>
