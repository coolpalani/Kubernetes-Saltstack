{%- set k8sVersion = pillar['kubernetes']['version'] -%}
{%- set masterCount = pillar['kubernetes']['master']['count'] -%}
{% set post_install_files = [
  "rbac-tiller.yaml", "setup.sh"] %}

include:
  - .etcd

/usr/bin/kube-apiserver:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/amd64/kube-apiserver
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kube-controller-manager:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/amd64/kube-controller-manager
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kube-scheduler:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/amd64/kube-scheduler
    - skip_verify: true
    - group: root
    - mode: 755

/usr/bin/kubectl:
  file.managed:
    - source: https://storage.googleapis.com/kubernetes-release/release/{{ k8sVersion }}/bin/linux/amd64/kubectl
    - skip_verify: true
    - group: root
    - mode: 755
{% if masterCount == 1 %}
/etc/systemd/system/kube-apiserver.service:
    file.managed:
    - source: salt://{{ slspath }}/kube-apiserver.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644
{% elif masterCount == 3 %}
/etc/systemd/system/kube-apiserver.service:
    file.managed:
    - source: salt://{{ slspath }}/kube-apiserver-ha.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644
{% endif %}

/etc/systemd/system/kube-controller-manager.service:
  file.managed:
    - source: salt://{{ slspath }}/kube-controller-manager.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/etc/systemd/system/kube-scheduler.service:
  file.managed:
    - source: salt://{{ slspath }}/kube-scheduler.service
    - user: root
    - template: jinja
    - group: root
    - mode: 644

/var/lib/kubernetes/encryption-config.yaml:
    file.managed:
    - source: salt://{{ slspath }}/encryption-config.yaml
    - user: root
    - template: jinja
    - group: root
    - mode: 644

{%- set cniProvider = pillar['kubernetes']['worker']['networking']['provider'] -%}
{% if cniProvider == "calico" %}

/opt/calico.yaml:
    file.managed:
    - source: salt://{{ slspath.split('/')[0] }}/k8s-worker/cni/calico/calico.tmpl.yaml
    - user: root
    - template: jinja
    - group: root
    - mode: 644
{% endif %}

{% for file in post_install_files %}
/opt/kubernetes/post_install/{{ file }}:
  file.managed:
  - source: salt://{{ slspath.split('/')[0] }}/post_install/{{ file }}
  - makedirs: true
  - template: jinja
  - user: root
  - group: root
{% if file == "setup.sh" %}
  - mode: 755
{% else %}
  - mode: 644
{% endif %}
{% endfor %}

kube-apiserver:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kube-apiserver.service
      - /var/lib/kubernetes/kubernetes.pem
kube-controller-manager:
  service.running:
    - enable: True
    - watch:
      - /etc/systemd/system/kube-controller-manager.service
      - /var/lib/kubernetes/kubernetes.pem
kube-scheduler:
  service.running:
   - enable: True
   - watch:
     - /etc/systemd/system/kube-scheduler.service
     - /var/lib/kubernetes/kubernetes.pem
