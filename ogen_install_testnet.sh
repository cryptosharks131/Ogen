TMP_FOLDER=$(mktemp -d)
COIN_REPO='https://public.oly.tech/olympus/release/v0.0.1/ogen-0.0.1-linux-amd64.tar.gz'
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

function initialize() {
  killall ogen
  if [ ! -d "$HOME/.config/" ]; then
    mkdir $HOME/.config/
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

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=Ogen Daemon
After=network.target
[Service]
ExecStart=/usr/local/bin/ogen --enablemining=true --rpc_wallet --rpc_proxy
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

function reset_node() {
  ogen reset >/dev/null 2>&1
}

function create_wallet() {
  echo -e "Enter a name for your ${RED}Olympus${NC} wallet:"
  read -e WALLET_NAME
  curl -X POST --data '{"name":"$WALLET_NAME"}' localhost:8080/wallet/createwallet
  echo -e ""
  curl -X POST --data '{"name":"$WALLET_NAME"}' localhost:8080/wallet/openwallet
  echo -e ""
  echo -e "Created and opened wallet with name: ${RED}$WALLET_NAME${NC}"
  echo -e "Please make sure to remember or record your wallet name."
  echo -e ""
}

function create_validators() {
  echo -e "Please enter the ${RED}number of validators${NC} you would like to start.  You may start up to 128 validators."
  read -e NUM_VALIDATORS
  if $NUM_VALIDATORS > 0 && $NUM_VALIDATORS < 129; then
    echo "Number of validators must be between 1 and 128.  Please try again."
    read -e NUM_VALIDATORS
  fi
  REQ_BALANCE=(($NUM_VALIDATORS)*100)
  echo -e "A ${RED}balance of $REQ_BALANCE${NC} is required to start your validators. Press any key to continue after deposit is made."
  read -e
}

#Start Script
clear

initialize
install_node
reset_node
configure_systemd
create_wallet
create_validators

