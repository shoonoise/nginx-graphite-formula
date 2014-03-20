nginx-package:
  pkg.latest:
    - pkgs:
      - nginx

{% set ssl_enabled = False  %}
{% set ssl_key_file = '' %}
{% set ssl_crt_file = '' %}

{% if pillar.get('ssl:key-file', '') %}
{% set ssl_enabled = True  %}
{% set ssl_key_file = pillar.get('ssl:key-file')  %}
{% set ssl_crt_file = pillar.get('ssl:cert-file') %}

/etc/ssl/private/{{ ssl_key_file }}:
  file.managed:
    - source: salt://nginx-graphite/files/{{ ssl_key_file }}
    - owner: root
    - group: ssl-cert
    - file_mode: 640
    - watch_in:
      - service: nginx

/etc/ssl/certs/{{ ssl_crt_file }}:
  file.managed:
    - source: salt://nginx-graphite/files/{{ ssl_crt_file }}
    - owner: root
    - group: root
    - file_mode: 644
    - watch_in:
      - service: nginx
{% endif -%}

graphite-available:
  file.managed:
    - name: /etc/nginx/sites-available/graphite
    - source: salt://nginx-graphite/files/graphite.conf
    - template: jinja
    - context:
      ssl_enabled: {{ ssl_enabled }}
      ssl_key_file: {{ ssl_key_file }}
      ssl_crt_file: {{ ssl_crt_file }}

graphite-enabled:
  file.symlink:
    - name: /etc/nginx/sites-enabled/graphite
    - target: /etc/nginx/sites-available/graphite
    - force: True
    - watch:
      - file: graphite-available

nginx:
  service.running:
    - watch:
      - pkg: nginx-package
      - file: graphite-enabled
      - file: graphite-available
