#!/bin/sh

JKS_FILE=/opt/SP/m2muser/KSSV/keystore/kssv-keystore.jck
#JKS_PASSWORD=Secret123
JKS_STORETYPE=jceks

while [[ $# -gt 0 ]]; do
  case "$1" in
    -dev)
      echo "The '-dev' argument is present."
      # You can add your code here for what to do when "-dev" is present
      environment="dev"
      JKS_PASSWORD="changeit"
      token="00000000-0000-0000-0000-000000000000"
      JKS_FILE=run/keystore.jceks
      ;;
    *)
      # Handle other arguments here if needed
      ;;
  esac
  shift
done

if [ "$environment" != "dev" ]; then
  PS3="Select an environment (1-4): "
  options=("lit" "e2e" "stg" "prd")

  select choice in "${options[@]}"; do
    case $REPLY in
      1) environment="lit"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/non-prod"; break;;
      2) environment="lob"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/non-prod"; break;;
      3) environment="sta"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/prod"; break;;
      4) environment="prd"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/prod"; break;;
      *) echo "Invalid option. Please select a valid number (1-4).";;
    esac
  done

  echo "You selected the environment: $environment"

  read -s -p "Enter JKS password: " JKS_PASSWORD

  echo

  read -s -p "Enter VAULT token: " token
fi

export VAULT_TOKEN=$token

# Extract the list of aliases (keys) from the JKS file
KEY_ALIASES=$(keytool -list -keystore "$JKS_FILE" -storetype "$JKS_STORETYPE" -storepass "$JKS_PASSWORD" -v | grep "Alias name" | cut -d " " -f 3)

json_string="{"

# Loop through the key aliases and write them to Vault
for ALIAS in $KEY_ALIASES; do
  # Extract the key value from the JKS for each alias
  KEY_VALUE=$(java -jar jceks-tool-0.1.1.jar show -k "$JKS_FILE" -p "$JKS_PASSWORD" -a "$ALIAS" -e "$JKS_PASSWORD" | sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' | sed '1d;$d')

  json_string="$json_string\"${ALIAS}\": \"${KEY_VALUE}\","

  # Display a message indicating the key migration
  echo "It will be migrated key '$ALIAS' to Vault"
done

if [ "${json_string: -1}" = "," ]; then
  json_string="${json_string%,}"
fi

json_string="$json_string}"

# Specify the output JSON file
json_file="data.json"

echo "$json_string" > "$json_file"

# Write the key and value to Vault as a generic secret
if [ "$environment" == "dev" ]; then
  vault kv put -address="http://127.0.0.1:8201" -mount=kssv $environment @data.json
else
  /opt/SP/apps/vault/vault kv put -address="https://secrets.vault.vodafone.com/" -namespace=$namespace -mount=secrets kssv/$environment @data.json
fi
rm data.json