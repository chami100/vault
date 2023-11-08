JKS_FILE=/opt/SP/m2muser/KSSV/keystore/kssv-keystore.jck
#JKS_PASSWORD=Secret123
JKS_STORETYPE=jceks

PS3="Select an environment (1-4): "
options=("lit" "e2e" "stg" "prd")

select choice in "${options[@]}"; do
  case $REPLY in
    1) environment="lit"; break;;
    2) environment="e2e"; break;;
    3) environment="stg"; break;;
    4) environment="prd"; break;;
    *) echo "Invalid option. Please select a valid number (1-4).";;
  esac
done

echo "You selected the environment: $environment"

read -s -p "Enter JKS password: " JKS_PASSWORD

echo

read -s -p "Enter VAULT token: " token
export VAULT_TOKEN=$token

# Extract the list of aliases (keys) from the JKS file
KEY_ALIASES=$(keytool -list -keystore "$JKS_FILE" -storetype "$JKS_STORETYPE" -storepass "$JKS_PASSWORD" -v | grep "Alias name" | cut -d " " -f 3)

json_string="{"

# Loop through the key aliases and write them to Vault
for ALIAS in $KEY_ALIASES; do
  # Extract the key value from the JKS for each alias
  KEY_VALUE=$(java -jar /opt/SP/apps/vault/jceks-tool-0.1.1.jar show -k "$JKS_FILE" -p "$JKS_PASSWORD" -a "$ALIAS" -e "$JKS_PASSWORD" | sed -n '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/ {/BEGIN PRIVATE KEY/n; /END PRIVATE KEY/!p}')

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
/opt/SP/apps/vault/vault kv put -address="https://secrets.vault.vodafone.com/" -namespace=secrets/vf-eiot/iot-connectivity/iotmc/non-prod -mount=secrets kssv/$environment @data.json
rm data.json