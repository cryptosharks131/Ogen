TMP_FOLDER=$(mktemp -d)
COIN_REPO='https://public.oly.tech/olympus/ogen-release/ogen-0.0.1-linux-amd64.tar.gz'
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

function create_wallet() {
  echo -e "Enter the name of your ${RED}Olympus${NC} wallet to be opened or created:"
  read -e WALLET_NAME
  echo -e "Enter the password for your ${RED}Olympus${NC} wallet to be opened or created:"
  read -e WALLET_PASSWORD
  clear
  ADDRESS=$(curl -s -k -X POST --data '{"name":"'$WALLET_NAME'","password":"'$WALLET_PASSWORD'"}' https://localhost:8080/wallet/create | grep -o '"public":"[^"]*' | cut -d'"' -f4)
  WALLET_OPEN=$(curl -s -k -X POST --data '{"name":"'$WALLET_NAME'","password":"'$WALLET_PASSWORD'"}' https://localhost:8080/wallet/open)
  echo -e ""
  if ! [ "$WALLET_OPEN" == '{"success":true}' ] >/dev/null 2>&1; then
    echo -e "Error while opening wallet.  Exiting script."
    rm /etc/systemd/system/Olympus.service
    killall ogen
    exit
  fi
  if [ "$ADDRESS" == '' ] >/dev/null 2>&1; then
    echo -e "Wallet already exists."
    ADDRESS=$(curl -s -k -X GET https://localhost:8080/wallet/account | grep -o '"public":"[^"]*' | cut -d'"' -f4)
  fi
  echo -e "Created and opened wallet with name: ${RED}$WALLET_NAME${NC}"
  echo -e "Please make sure to remember or record your wallet name and password!"
  echo -e "Your wallet's address is: $ADDRESS"
  echo -e ""
}

function create_validators() {
  echo -e "Please enter the ${RED}number of validators${NC} you would like to start.  You may start up to 128 validators."
  read -e NUM_VALIDATORS
  if ! [ "$NUM_VALIDATORS" -ge 1 ] >/dev/null 2>&1 || ! [ "$NUM_VALIDATORS" -le 128 ] >/dev/null 2>&1; then
    echo "Number of validators must be between 1 and 128.  Please try again."
    read -e NUM_VALIDATORS
    if ! [ "$NUM_VALIDATORS" -ge 1 ] >/dev/null 2>&1 || ! [ "$NUM_VALIDATORS" -le 128 ] >/dev/null 2>&1; then
      echo -e "Failed to get number of validators.  Script exiting."
      rm /etc/systemd/system/Olympus.service
      killall ogen
      exit
    fi
  fi
  REQ_BALANCE=`expr $NUM_VALIDATORS \* 100`
  echo -e ""
  echo -e "A ${RED}balance of $REQ_BALANCE${NC} is required to start your validators. Press any key to continue after deposit is made."
  read -e
  BALANCE=$(curl -s -k -X GET https://localhost:8080/wallet/balance | grep -o '"confirmed":"[^"]*' | cut -d'"' -f4)
  echo -e "Balance of $BALANCE detected."
  if [ "$BALANCE" -lt $REQ_BALANCE ] >/dev/null 2>&1; then
    echo -e "Insufficient balance, please confirm deposit is complete.  Please any key to continue when ready."
    read -e
    if [ "$BALANCE" -lt $REQ_BALANCE ] >/dev/null 2>&1; then
      echo -e "Cannot confirm sufficient balance.  Exiting script."
      rm /etc/systemd/system/Olympus.service
      killall ogen
      exit
    fi
  fi
  VAL_KEYS=$(curl -s -k -X POST --data '{"keys":'$NUM_VALIDATORS'}' https://localhost:8080/utils/genvalidatorkey)
  echo -e ""
  VAL_SUCCESS=$(curl -s -k -X POST --data $VAL_KEYS https://localhost:8080/wallet/startvalidatorbulk)
  echo -e ""
  if ! [ "$VAL_SUCCESS" == '{"success":true}' ] >/dev/null 2>&1; then
    echo -e "Cannot start validators.  Exiting script."
    rm /etc/systemd/system/Olympus.service
    killall ogen
    exit
  fi
  echo -e "Created $NUM_VALIDATORS validators."
  echo -e "Your validators keys are below:"
  echo -e $VAL_KEYS
  echo -e "Script complete."
}

#Start Script
clear

create_wallet
create_validators
