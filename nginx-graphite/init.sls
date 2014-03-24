nginx-package:
  pkg.latest:
    - pkgs:
      - nginx

{%- if salt['pillar.get']('ssl:key-file') -%}
/etc/ssl/private/{{ salt['pillar.get']('ssl:key-file') }}:
  file.managed:
    - source: salt://nginx-graphite/files/{{ salt['pillar.get']('ssl:key-file') }}
    - owner: root
    - group: ssl-cert
    - file_mode: 640
    - watch_in:
      - service: nginx

/etc/ssl/certs/{{ salt['pillar.get']('ssl:cert-file') }}:
  file.managed:
    - source: salt://nginx-graphite/files/{{ salt['pillar.get']('ssl:cert-file') }}
    - owner: root
    - group: root
    - file_mode: 644
    - watch_in:
      - service: nginx
{% endif %}

graphite-available:
  file.managed:
    - name: /etc/nginx/sites-available/graphite
    - source: salt://nginx-graphite/files/graphite.conf
    - template: jinja
    - context:
      lua_enabled: False

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
