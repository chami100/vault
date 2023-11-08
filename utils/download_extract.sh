PS3="Select an environment (1-4): "
options=("lit" "lob" "sta" "prd" "dev")

select choice in "${options[@]}"; do
  case $REPLY in
    1) environment="lit"; break;;
    2) environment="lob"; break;;
    3) environment="sta"; break;;
    4) environment="prd"; break;;
    5) environment="dev"; break;;
    *) echo "Invalid option. Please select a valid number (1-5).";;
  esac
done

echo "You selected the environment: $environment"

if [ "$environment" != "dev" ]; then
    export HTTPS_PROXY="http://prx-v1.$environment.m2m.vodafone.com:9401"
fi

architecture=$(arch)

vault_url="https://releases.hashicorp.com/vault/1.15.1/vault_1.15.1_linux_amd64.zip"

if [ "$architecture" == "arm64" ]; then
    vault_url="https://releases.hashicorp.com/vault/1.15.2/vault_1.15.2_darwin_arm64.zip"
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
else
  curl -O $vault_url
  unzip vault_1.15.1_*.zip
  rm vault_1.15.1_*.zip
fi

curl -O https://github.com/zappee/jceks-tool/blob/master/bin/jceks-tool-0.1.1.jar