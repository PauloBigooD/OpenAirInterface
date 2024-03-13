OAI 4G Core
---

### Introduction

General Instructions

In this task you will install and configure the Evolved Packet Core (EPC), which is the core of 4G network of LTE. There are two different versions
of the OAI EPC:

 1. The most updated version of EPC is available at github openair-epc-fed ;
 2. This version is used for simulation purposes, but it works very well with 4G RAN.

We will explore both installation, however we recommend you to use the most updated one.

:white_check_mark:
This tutorial is made from informations from official gitlab pages:

:sparkles:
[· develop · oai / openairinterface5G · GitLab (eurecom.fr)](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz/README.md)

:sparkles:
[· master · OPENAIRINTERFACE openair-epc-fed · GitHub](https://github.com/OPENAIRINTERFACE/openair-epc-fed/blob/master/docs/DEPLOY_HOME_MAGMA_MME.md)

---

### 🛠️ Pre-Requisites

Basically you need:
1. Laptop/Desktop/Server for OAI EPC and OAI eNB
   -  Ubuntu 18.04 or 20.04 Baremetal;
   -  CPU: 8 cores x86_64 @ 3.5 GHz.
   -  RAM: 32 GB
Install following libraries:

```bash
sudo apt-get update apt-get install -y git vim curl net-tools openssh-server python3-pip nfs-common
```

Some importants commands:

```bash
sudo sysctl net.ipv4.conf.all.forwarding=1

sudo iptables -P FORWARD ACCEPT
```
---

## RFSim4G EPC (MOD DEMO)

- [ ] Install and Build EPC

```
docker login

Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to
https://hub.docker.com to create one.
Username:

Password:

```

- [ ] Now Pull images:

```
docker pull cassandra:2.1
docker pull redis:6.0.5
docker pull oaisoftwarealliance/oai-hss:latest
docker pull oaisoftwarealliance/magma-mme:latest
docker pull oaisoftwarealliance/oai-spgwc:latest
docker pull oaisoftwarealliance/oai-spgwu-tiny:latest
docker pull oaisoftwarealliance/oai-enb:develop
docker pull oaisoftwarealliance/oai-lte-ue:develop
```

- [ ] Re-tag them:

```
docker image tag oaisoftwarealliance/oai-spgwc:latest oai-spgwc:latest
docker image tag oaisoftwarealliance/oai-hss:latest oai-hss:latest
docker image tag oaisoftwarealliance/oai-spgwu-tiny:latest oai-spgwu-tiny:latest
docker image tag oaisoftwarealliance/magma-mme:latest magma-mme:latest
```

- [ ] Clone directly on the latest release tag:

```
git clone --branch v1.2.0 https://github.com/OPENAIRINTERFACE/openair-epc-fed.git
cd openair-epc-fed
```

- [ ] If you forgot to clone directly to the latest release tag

```
$ git checkout -f v1.2.0
```

- [ ] Synchronize all git submodules

```
./scripts/syncComponents.sh
```

## Deploy OAI CN4G container

- [ ] Deploy and Configure Demo Cassandra Database

```
cd openair-epc-fed/docker-compose/magma-mme-demo
docker-compose up -d db_init
```

- [ ] Make sure everything is ok!

```
docker ps -a
```

:triangular_flag_on_post:
The next commands can only be used when you got the "OK" message by using the command below:
`docker logs demo-db-init --follow`

- [ ] Remove once it is not need anymore:

```
docker rm -f demo-db-init
```

- [ ] Deploy Magma-MME

```
docker-compose up -d oai_spgwu
```

- [ ] Get EPC logs

:triangular_flag_on_post:
make sure the NAME of the pod is correct, use:  `docker ps -a`

```
docker exec -it demo-magma-mme /bin/bash -c "tail -f /var/log/mme.log"
```
