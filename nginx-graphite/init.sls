{% if grains['os'] == 'Ubuntu' %}
nginx-repo:
  pkgrepo.managed:
    - ppa: nginx/stable
    - require_in:
      - pkg: nginx-package
{% endif %}

nginx-package:
  pkg.latest:
    - pkgs:
      - nginx-extras
      - liblua5.1-json

{% if salt['pillar.get']('ssl:key-file') %}
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

{% for luafile in ['collect_stats.lua','show_stat.lua','common_stat.lua'] %}
/etc/nginx/{{ luafile }}:
  file.managed:
    - source: salt://nginx-graphite/files/lua/{{ luafile }}
    - owner: root
    - group: root
    - file_mode: 644
    - watch_in:
      - service: nginx
{% endfor %}

graphite-available:
  file.managed:
    - name: /etc/nginx/sites-available/graphite
    - source: salt://nginx-graphite/files/graphite.conf
    - template: jinja

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
