#!/bin/bash

## Paulo Eduardo da Silva Junior - paulo.eduardo.093@ufrn.edu.br

set -e

## Work directory path is the current directory
WORK_DIR=$PWD

command="$1"
case "${command}" in
	"--help")
		echo "Common Commands: 
 --start   = Start EPC 4G
 --stop    = Stop EPC 4G  
 --eNB     = Start eNB 4G  
 --logs    = EPC 4G logs  
 --install = Install all dependences for EPC 4G"
		;;
	"--stop")
                cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
                sudo docker-compose down
		;;
	"--install")
                ## OAI RAN/UE 4G/5G Installation
                sudo add-apt-repository ppa:ettusresearch/uhd
                sudo apt-get install libuhd-dev uhd-host -y
                sudo apt-get install libuhd4.2.0 -y
                sudo dpkg -i --force-overwrite /var/cache/apt/archives/libuhd4.2.0_4.2.0.1-0ubuntu1~focal1_amd64.deb
                sudo apt-get install libuhd4.4.0 -y
                sudo dpkg -i --force-overwrite /var/cache/apt/archives/libuhd4.4.0_4.4.0.0-0ubuntu1~focal1_amd64.deb
                ## Clone OpenAirInterface 5G RAN repository
                git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
                cd $WORK_DIR/openairinterface5g
                git checkout develop
                ## Install OAI dependencies and Build OAI UE and eNB
                source oaienv
                cd cmake_targets
                sudo ./build_oai -I
                sudo ./build_oai -I --install-optional-packages
                sudo ./build_oai -w USRP --ninja --eNB --UE -C
                ## Docker Install
                ## Uninstall any such older versions before attempting to install a new version
                sudo apt-get remove docker docker-engine docker.io containerd runc -y
                ## Update the apt package index and install packages to allow apt to use a repository over HTTPS:
                sudo apt-get update -y
                sudo apt-get install ca-certificates curl gnupg -y
                ## Add Docker’s official GPG key
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                ## set up the repository
                echo \
                "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                ## Install Docker Engine
                sudo apt-get update -y
                sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
                ## Pulling the images from Docker Hub
                sudo docker login
                sudo docker pull cassandra:2.1
                sudo docker pull redis:6.0.5
                sudo docker pull oaisoftwarealliance/oai-hss:latest
                sudo docker pull oaisoftwarealliance/magma-mme:latest
                sudo docker pull oaisoftwarealliance/oai-spgwc:latest
                sudo docker pull oaisoftwarealliance/oai-spgwu-tiny:latest
                sudo docker pull oaisoftwarealliance/oai-enb:develop
                sudo docker pull oaisoftwarealliance/oai-lte-ue:develop
                ## Re-tag
                sudo docker image tag oaisoftwarealliance/oai-spgwc:latest oai-spgwc:latest
                sudo docker image tag oaisoftwarealliance/oai-hss:latest oai-hss:latest
                sudo docker image tag oaisoftwarealliance/oai-spgwu-tiny:latest oai-spgwu-tiny:latest
                sudo docker image tag oaisoftwarealliance/magma-mme:latest magma-mme:latest
		;;
	"--start")
		## Performance mode
		sudo /etc/init.d/cpufrequtils restart
                ## Configuration of the packer forwarding
		sudo sysctl net.ipv4.conf.all.forwarding=1
		sudo iptables -P FORWARD ACCEPT
		## Deploy and Configure Cassandra Database
                cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
                ## Un-deployment olds containers
                sudo docker-compose down
                ## Deploy and Configure Cassandra Database
                sudo docker-compose up -d db_init
                sleep 15
                ## log init
                sudo docker logs rfsim4g-db-init --follow
                sleep 10
                sudo docker rm rfsim4g-db-init
                ## Deploy Magma-MME
                sleep 5
                sudo docker-compose up -d magma_mme oai_spgwu trf_gen
                ## Container list
                sudo docker-compose ps -a
		;;
        "--eNB")
                ## eNodeB Monolithic (USRP) deployment
                cd $WORK_DIR/openairinterface5g/cmake_targets/ran_build/build/
                sudo -E ./lte-softmodem -O ../../../ci-scripts/conf_files/enb.band7.100prb.usrpb200.tm1.conf
                ;;
        "--logs")
                ## EPC logs
                sudo docker exec -it rfsim4g-magma-mme /bin/bash -c "tail -f /var/log/mme.log"
                ;;
	*)
		echo " Command not Found."
		echo "Common Commands: 
 --start   = Start EPC 4G
 --stop    = Stop EPC 4G  
 --eNB     = Start eNB 4G  
 --logs    = EPC 4G logs  
 --install = Install all dependences for EPC 4G"
		exit 127;
		;;
esac