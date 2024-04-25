#!/bin/bash

## Author:   Paulo Eduardo da Silva Junior - paulo.eduardo.093@ufrn.edu.br - Tel: +55 (84) 9 8808-0933
## GitHub:   https://github.com/PauloBigooD
## Linkedin: https://www.linkedin.com/in/paulo-eduardo-5a18b3174/

set -e

## Work directory path is the current directory
WORK_DIR=$PWD

## Definindo o URL do repositório
repo_url="https://gitlab.eurecom.fr/oai/openairinterface5g.git"

command="$1"
case "${command}" in
	"--help")
		echo "Common Commands: 
 --install = Install all dependences for EPC 4G
 --start   = Start EPC 4G
 --stop    = Stop EPC 4G  
 --eNB     = Start eNB 4G
 --eNB-sim = Start eNB 4G Simulada
 --ue-sim  = Start UE 4G Simulado 
 --logs    = EPC 4G logs"
		;;
	"--stop")
            cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
            sudo docker-compose down
		;;
	"--install")
            echo "OAI RAN/UE 4G/5G Installation"
            sudo add-apt-repository ppa:ettusresearch/uhd
	    
	    # Verifica se o pacote libuhd4.6.0 está instalado
	    if dpkg -l | grep -q libuhd4.6.0; then
    		echo "Pacote libuhd4.6.0 já instalado."
	    else
    		# Instala o pacote libuhd4.6.0
    		sudo apt-get install libuhd-dev uhd-host -y
		sudo apt-get install libuhd4.6.0 -y && \
                sudo dpkg -i --force-overwrite /var/cache/apt/archives/libuhd4.6.0_4.6.0.0-0ubuntu1~focal1_amd64.deb || \
                sudo dpkg -i --force-overwrite /var/cache/apt/archives/libuhd4.6.0_4.6.0.0-0ubuntu1~focal1_amd64.deb
	    fi
            
	    if dpkg -l | grep -q git; then
                echo "Pacote git já instalado."
            else
            	sudo apt-get install git -y
	    fi

	    echo "Clone OpenAirInterface 5G RAN repository"
            
	    # Verificando se o repositório existe
            if [ -d "openairinterface5g" ]; then
                echo "Removendo o diretório existente 'openairinterface5g'..."
                rm -rf openairinterface5g
            fi

            # Verifica novamente se o diretório foi removido com sucesso
            if [ ! -d "openairinterface5g" ]; then
                # Se não existir mais, clona o repositório
                git clone "$repo_url"
                cd $WORK_DIR/openairinterface5g
                git checkout develop
            else
                echo "Erro: Não foi possível remover o diretório 'openairinterface5g'."
            fi
		
            echo "Install OAI dependencies and Build OAI UE and eNB"
            source oaienv
            cd cmake_targets
            sudo ./build_oai -I
            sudo ./build_oai -I --install-optional-packages
            sudo ./build_oai -w USRP --nrUE --eNB --UE -C --build-lib "telnetsrv enbscope uescope nrscope nrqtscope"
                
            echo "Uninstall Docker any such older versions before attempting to install a new version"
            sudo apt-get remove docker docker-engine docker.io containerd runc 
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
                
	    echo "Install Docker Engine"
            sudo apt-get update -y
            sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
                
	    echo "Pulling the images from Docker Hub"
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
	    #sudo /etc/init.d/cpufrequtils restart
            ## Configuration of the packer forwarding
	    sudo sysctl net.ipv4.conf.all.forwarding=1
	    sudo iptables -P FORWARD ACCEPT
	    echo "Deploy and Configure Cassandra Database"
            cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
            ## Un-deployment olds containers
            sudo docker-compose down
            ## Deploy and Configure Cassandra Database
            sudo docker-compose up -d db_init
            ## Run docker command in background
		    sudo docker logs rfsim4g-db-init --follow &
		    ## Monitor docker command output
		    while :
		    do
		        ## Checks if the command output contains "OK"
		        if sudo docker logs rfsim4g-db-init | grep -q "OK"; then
		            echo "Status OK!"
	                sudo docker rm rfsim4g-db-init
			        ## Deploy Magma-MME
        	        sleep 5
               		sudo docker-compose up -d magma_mme oai_spgwu trf_gen
	                ## Container list
			        sleep 5
	                sudo docker-compose ps -a
			    break
		        fi
		        sleep 20
		    done
		;;
        "--eNB")
                ## eNodeB Monolithic (USRP) deployment
                cd $WORK_DIR/openairinterface5g/cmake_targets/ran_build/build/
                sudo -E ./lte-softmodem -O ../../../ci-scripts/conf_files/enb.band7.100prb.usrpb200.tm1.conf
                ;;
        "--eNB-docker")
                ## eNodeB Docker
                cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
                sudo docker-compose up -d oai_enb0
		;;
        "--ue-docker")
                ## eNodeB Docker
                cd $WORK_DIR/openairinterface5g/ci-scripts/yaml_files/4g_rfsimulator_fdd_05MHz
                sudo docker-compose up -d oai_ue0
                ;;
        "--eNB-sim")
                ## eNodeB Simulator
                cd $WORK_DIR/openairinterface5g/cmake_targets/ran_build/build/
                sudo -E ./lte-softmodem --rfsim --log_config.global_log_options level,nocolor,time -O ../../../ci-scripts/conf_files/enb.band7.25prb.rfsim.conf --eNBs.[0].rrc_inactivity_threshold 0 2>&1 -d
                ;;
        "--ue-sim")
                ## eNodeB Simulator
                cd $WORK_DIR/openairinterface5g/cmake_targets/ran_build/build/
                sudo -E ./lte-uesoftmodem --rfsim -C 2680000000 -r 25 --ue-rxgain 140 --ue-txgain 120 --rfsimulator.serveraddr 192.168.61.20 --log_config.global_log_options level,nocolor,time -O ../../../ci-scripts/conf_files/lteue.usim-ci.conf #-d
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
 --eNB-sim = Start eNB 4G Simulada
 --ue-sim  = Start UE 4G Simulado
 --logs    = EPC 4G logs  
 --install = Install all dependences for EPC 4G"
		exit 127;
		;;
esac
