#!/bin/sh

while [[ $# -gt 0 ]]; do
  case "$1" in
    -dev)
      echo "The '-dev' argument is present."
      # You can add your code here for what to do when "-dev" is present
      environment="dev"
      ;;
    *)
      # Handle other arguments here if needed
      ;;
  esac
  shift
done

if [ "$environment" != "dev" ]; then
  PS3="Select an environment (1-4): "
  options=("lit" "lob" "sta" "prd")

  select choice in "${options[@]}"; do
    case $REPLY in
      1) environment="lit"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/non-prod"; break;;
      2) environment="lob"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/non-prod"; break;;
      3) environment="sta"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/prod"; break;;
      4) environment="prd"; namespace="secrets/vf-eiot/iot-connectivity/iotmc/prod"; break;;
      *) echo "Invalid option. Please select a valid number (1-5).";;
    esac
  done
  echo "You selected the environment: $environment"
  /opt/SP/apps/vault/vault kv get -address="http://127.0.0.1:18100" -namespace=$namespace -mount=secrets kssv/$environment

  curl \
      -H "X-Vault-Token: <TOKEN>" \
      -H "X-Vault-Namespace: secrets/vf-eiot/iot-connectivity/iotmc/non-prod" \
      -X GET \
      https://secrets.vault.vodafone.com/v1/secrets/data/config-server/application/prd

else
  vault kv get -address="http://127.0.0.1:18100" -mount=kssv $environment

  curl \
      -H "X-Vault-Token: <TOKEN>" \
      -X GET \
      http://127.0.0.1:8201/v1/config-server/data/application/prd
fi