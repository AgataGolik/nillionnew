#!/bin/bash

echo ""
echo "Follow: https://x.com/ZunXBT"
read -p "Have you followed @ZunXBT on X? (y/Y to proceed): " FOLLOWED

if [[ ! "$FOLLOWED" =~ ^[yY]$ ]]; then
    echo ""
    echo "Please follow @ZunXBT on X before proceeding."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo ""
    echo "Docker not found. Installing Docker..."
    sudo apt update && sudo apt install -y curl && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sudo sh get-docker.sh
    sudo usermod -aG docker ${USER} && su - ${USER} -c "groups"
else
    echo ""
    echo "Docker is already installed."
fi

sudo apt update && sudo apt install -y jq bc screen

echo ""
read -p "How many accusers do you want to run? " NUM_ACCUSERS

for ((i=1; i<=NUM_ACCUSERS; i++)); do
    ACCUSER_DIR="nillion/accuser_$i"
    
    if [ -d "$ACCUSER_DIR" ]; then
        echo ""
        echo "'$ACCUSER_DIR' directory found. Removing..."
        sudo rm -r "$ACCUSER_DIR"
    fi

    echo ""
    echo "Creating directory and running Docker container to initialize accuser $i..."
    mkdir -p "$ACCUSER_DIR" && \
    sudo docker run -v "$(pwd)/$ACCUSER_DIR:/var/tmp" nillion/retailtoken-accuser:latest initialise

    SECRET_FILE="$ACCUSER_DIR/credentials.json"
    if [ -f "$SECRET_FILE" ]; then
        ADDRESS=$(jq -r '.address' "$SECRET_FILE")
        echo ""
        echo "Request nillion faucet (https://faucet.testnet.nillion.com) to your accuser $i wallet address: $ADDRESS"
        echo ""

        read -p "Have you requested the faucet to the accuser $i wallet? (y/Y to proceed): " FAUCET_REQUESTED1
        if [[ "$FAUCET_REQUESTED1" =~ ^[yY]$ ]]; then
            echo ""
            echo "Now visit: https://verifier.nillion.com/verifier"
            echo "Connect a new Keplr wallet for accuser $i."
            echo "Request faucet to the nillion address : https://faucet.testnet.nillion.com"
            echo ""

            read -p "Have you requested faucet to your Keplr wallet for accuser $i? (Y/y to proceed): " FAUCET_REQUESTED2
            if [[ "$FAUCET_REQUESTED2" =~ ^[yY]$ ]]; then
                read -p "Input your Keplr wallet's nillion address for accuser $i: " KEPLR
                echo ""
                echo "Input the following information on the website: https://verifier.nillion.com/verifier"
                echo "Address: $ADDRESS"
                echo "Public Key: $(jq -r '.pub_key' "$SECRET_FILE")"
                echo ""

                read -p "Have you done this? (Y/y to proceed): " address_submitted
                if [[ "$address_submitted" =~ ^[yY]$ ]]; then
                    echo ""
                    echo "Save this Private Key for accuser $i in safe place: $(jq -r '.priv_key' "$SECRET_FILE")"
                    echo ""
                    read -p "Have you saved the private key in a safe place? (y/Y to proceed): " private_key_saved
                    if [[ "$private_key_saved" =~ ^[yY]$ ]]; then
                        echo ""
                        echo "Running Docker container with accuse command for accuser $i in a new screen session..."
                        screen -dmS "accuser_$i" bash -c "sudo docker run -v \"$(pwd)/$ACCUSER_DIR:/var/tmp\" nillion/retailtoken-accuser:latest accuse --rpc-endpoint \"https://nillion-testnet-rpc.polkachu.com\" --block-start \"\$(curl -s https://nillion-testnet-rpc.polkachu.com/abci_info | jq -r '.result.response.last_block_height')\""
                    else
                        echo ""
                        echo "Please save the private key for accuser $i and try again."
                    fi
                else
                    echo ""
                    echo "Please complete the submission for accuser $i and try again."
                fi
            else
                echo ""
                echo "Please request the faucet to your Keplr wallet for accuser $i and try again."
            fi
        else
            echo ""
            echo "Please request the faucet for accuser $i and try again."
        fi
    else
        echo ""
        echo "credentials.json file not found for accuser $i. Ensure the initialization step completed successfully."
    fi
done

echo ""
echo "All accusers have been set up. You can check their status using 'screen -list' and attach to a specific accuser using 'screen -r accuser_X' where X is the accuser number."
