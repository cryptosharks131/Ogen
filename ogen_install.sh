TMP_FOLDER=$(mktemp -d)
COIN_REPO='https://public.oly.tech/olympus/release/v0.0.1/ogen-0.0.1-linux-amd64.tar.gz'
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

function initialize() {
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

function start_node() {
  screen -S Ogen
  ogen reset
  ogen --enablemining=true
  screen -s OgenCli
}

function start_validator() {
}

#Start Script
clear

initialize
install_node
start_node
