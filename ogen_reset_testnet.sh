TMP_FOLDER=$(mktemp -d)
COIN_REPO='https://github.com/olympus-protocol/ogen/releases/download/v0.2.0-alpha.1/ogen-0.2.0-alpha.1-linux-amd64.tar.gz'
COIN_NAME='Olympus'
COIN_DAEMON='ogen'
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

function reset() {
  killall ogen >/dev/null 2>&1
  if [ ! -d "$HOME/.config/" ]; then
    mkdir $HOME/.config/
  fi
  if [ -d "/etc/systemd/system/$COIN_NAME.service" ]; then
    rm /etc/systemd/system/$COIN_NAME.service
  fi
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=Ogen Daemon
After=network.target
[Service]
ExecStart=/usr/local/bin/$COIN_DAEMON --rpc_wallet --rpc_proxy --dashboard --network testnet
Type=simple
User=root
Restart=on-failure
TimeoutStopSec=300
WorkingDirectory=/root/.config/ogen
LimitNOFILE=500000
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true
#MemoryDenyWriteExecute=true
#StandardOutput=append:/var/log/ogen.log
#StandardError=append:/var/log/ogen_error.log
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function install_node() {
  echo -e "Prepare to download $COIN_NAME"
  cd $TMP_FOLDER
  wget -q $COIN_REPO
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  tar xvf $COIN_ZIP --strip 2 >/dev/null 2>&1
  compile_error
  cp ogen /usr/local/bin
  compile_error
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  clear
}

function reset_node() {
  ogen reset >/dev/null 2>&1
}

function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME is reset, updated and running!"
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

reset
install_node
reset_node
configure_systemd
important_information
