OAI 4G Core
---

### Introduction

General Instructions

In this task you will install and configure the Evolved Packet Core (EPC), which is the core of 4G network of LTE. There are two different versions
of the OAI EPC:

 1. The most updated version of EPC is available at github openair-epc-fed ;
 2. This version is used for simulation purposes, but it works very well with 4G RAN.

We will explore both installation, however we recommend you to use the most updated one.

> [!Note]

> This tutorial is made from informations from official gitlab pages:

[ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz/README.md · develop · oai / openairinterface5G · GitLab (eurecom.fr)](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz/README.md)

[openair-epc-fed/docs/DEPLOY_HOME_MAGMA_MME.md at master · OPENAIRINTERFACE openair-epc-fed · GitHub](https://github.com/OPENAIRINTERFACE/openair-epc-fed/blob/master/docs/DEPLOY_HOME_MAGMA_MME.md)

---

#### 🛠️ Pre-Requisites

Basically you need:
1. Laptop/Desktop/Server for OAI EPC and OAI eNB
 - a. Ubuntu 18.04 or 20.04 Baremetal;
 - b. CPU: 8 cores x86_64 @ 3.5 GHz.
 - c. RAM: 32 GB
Install following libraries:

```bash
sudo apt-get update apt-get install -y git vim curl net-tools openssh-server python3-pip nfs-common
```

Some importants commands:

```bash
sudo sysctl net.ipv4.conf.all.forwarding=1

sudo iptables -P FORWARD ACCEPT
```


> This is a note

> **Warning**
> This is a warning