#!/bin/bash

sudo -u ethereum bash <<'EOFC'

mkdir -p ~/.secret
openssl rand -hex 32 > ~/.secret/jwtsecret
chmod 440 ~/.secret/jwtsecret


export CHAIN=eth
export NETWORK=mainnet
export EXT_IP_ADDRESS_NAME=$CHAIN-$NETWORK-rpc-ip
export EXT_IP_ADDRESS=$(gcloud compute addresses list --filter=$EXT_IP_ADDRESS_NAME --format="value(address_range())")

nohup geth --datadir "/mnt/disks/chaindata-disk/ethereum/geth/chaindata" \
--http.corsdomain "*" \
--http \
--http.addr 0.0.0.0 \
--http.port 8545 \
--http.corsdomain "*" \
--http.api admin,debug,web3,eth,txpool,net \
--http.vhosts "*" \
--gcmode full \
--cache 2048 \
--mainnet \
--metrics \
--metrics.addr 127.0.0.1 \
--syncmode snap \
--authrpc.vhosts="localhost" \
--authrpc.port 8551 \
--authrpc.jwtsecret=/home/ethereum/.secret/jwtsecret \
--txpool.accountslots 32 \
--txpool.globalslots 8192 \
--txpool.accountqueue 128 \
--txpool.globalqueue 2048 \
--nat extip:$EXT_IP_ADDRESS \
&> "/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log" &

sudo chmod 666 /etc/google-cloud-ops-agent/config.yaml

sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /var/log/messages
      - /var/log/syslog

    ethGethLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log"]
      record_log_file_path: true

    ethLighthouseLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/lighthouse/logs/lighthouse.log"]
      record_log_file_path: true

    journalLog:
      type: systemd_journald

  service:
    pipelines:
      logging_pipeline:
        receivers:
        - syslog
        - journalLog
        - ethGethLog
        - ethLighthouseLog
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"

sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
metrics:
  receivers:
    prometheus:
        type: prometheus
        config:
          scrape_configs:
            - job_name: 'geth_exporter'
              scrape_interval: 10s
              metrics_path: /debug/metrics/prometheus
              static_configs:
                - targets: ['localhost:6060']
            - job_name: 'lighthouse_exporter'
              scrape_interval: 10s
              metrics_path: /metrics
              static_configs:
                - targets: ['localhost:5054']

  service:
    pipelines:
      prometheus_pipeline:
        receivers:
        - prometheus
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"

EOFC
