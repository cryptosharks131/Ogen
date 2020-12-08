TMP_FOLDER=$(mktemp -d)
COIN_REPO='https://github.com/olympus-protocol/ogen/releases/download/v0.1.3-alpha.9/ogen-0.1.3-alpha.9-linux-amd64.tar.gz'
COIN_NAME='Olympus'
RED='\033[0;31m'
NC='\033[0m'

function compile_error() {
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
    printf "${NC}"
    exit 1
  fi
}

function install_node() {
  systemctl stop $COIN_NAME
  echo -e "Prepare to download $COIN_NAME"
  cd $TMP_FOLDER
  wget -q $COIN_REPO
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  tar xvf $COIN_ZIP --strip 2 >/dev/null 2>&1
  compile_error
  rm /usr/local/bin/ogen
  cp ogen /usr/local/bin
  compile_error
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  systemctl start $COIN_NAME
  clear
}

function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME is updated and running!"
 echo -e "Configuration file is: ${RED}~/.config/ogen/${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e ""
 echo -e "You may view the dasahboard for this node by browsing the IP of your node on port 8080 in your web explorer. Eg. http://<vps_ip>:8080/"
 echo -e "================================================================================================================================"
}

#Start Script
clear

install_node
important_information
