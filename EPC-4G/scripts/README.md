## This repository contains some scripts that facilitate the provisioning of 4G and 5G OpenAirInterface systems

### The script that performs the EPC 4G provisioning is as follows

`EPC-4G.sh`

To use the script we first need to add execution permission with the command:

    chmod +x EPC-4G.sh

After adding the permission, simply run the following command:

    ./EPC-4G.sh --"option"

🌱 If in doubt, use `./EPC-4G.sh --help`

    --install = Install all dependences for EPC 4G
    --start   = Start EPC 4G
    --stop    = Stop EPC 4G 
    --eNB     = Start eNB 4G
    --eNB-sim = Start eNB 4G Simulated
    --ue-sim  = Start UE 4G Simulated 
    --logs    = EPC 4G logs`
