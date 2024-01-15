#!/bin/bash
set -x
set -e

cat <<EOF > /etc/haproxy/z-ingress.cfg
frontend fe-ingress-http
  bind *:80
  mode http
  option tcplog
  default_backend be-ingress-http

backend be-ingress-http
  mode http
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server ingress $INGRESS_EXTERNAL_IP:80 check

frontend fe-ingress-https
  bind *:443
  mode tcp
  option tcplog
  default_backend be-ingress-https

backend be-ingress-https
  mode tcp
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server ingress $INGRESS_EXTERNAL_IP:443 check
EOF
systemctl restart haproxy.service
