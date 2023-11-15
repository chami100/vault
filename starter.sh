#!/bin/bash
architecture=$(arch)

if [ "$architecture" == "arm64" ]; then
    status_default=$(colima -p default status 2>&1 | egrep "colima is running|arch: aarch64" | wc -l)
    if [ $status_default -lt 2 ]; then
        echo "starting default colima with aarch64"
        colima start --cpu 8 --memory 8 --arch aarch64
    else
        echo "already running default"
    fi
fi

docker-compose up -d
sleep 10

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault secrets enable -path=config-server kv-v2'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault secrets enable -path=kssv kv-v2'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv put -mount=config-server javatodev_core_api spring.datasource.database=javatodev_application_db spring.datasource.password=mauFJcuf5dhRMQrjj spring.datasource.username=root app.config.auth.token=5bd8b84a-7b9a-11ed-a1eb-0242ac120002 app.config.auth.username=actuator'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv put -mount=config-server javatodev_core_api/dev spring.datasource.database=javatodev_application_db spring.datasource.password=mauFJcuf5dhRMQrjj spring.datasource.username=root app.config.auth.token=34ef65f0-7b9d-11ed-a1eb-0242ac120002 app.config.auth.username=dev_user'

# docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv put secret/javatodev_core_api spring.datasource.database=javatodev_application_db spring.datasource.password=mauFJcuf5dhRMQrjj spring.datasource.username=root app.config.auth.token=5bd8b84a-7b9a-11ed-a1eb-0242ac120002 app.config.auth.username=actuator'
# docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv put secret/javatodev_core_api/dev spring.datasource.database=javatodev_application_db spring.datasource.password=mauFJcuf5dhRMQrjj spring.datasource.username=root app.config.auth.token=34ef65f0-7b9d-11ed-a1eb-0242ac120002 app.config.auth.username=dev_user'



docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault read /sys/mounts/config-server'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault read /sys/mounts/secret'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv metadata get -mount=config-server javatodev_core_api'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv list -mount=config-server'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault kv get -mount=config-server javatodev_core_api'


docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault auth enable ldap'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault policy write config-server-policy - << EOF
# Dev servers have version 2 of KV secrets engine mounted by default, so will
# need these paths to grant permissions:
path "config-server/*" {
  capabilities = ["read", "list"]
}
EOF'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault policy write kssv-policy - << EOF
# Dev servers have version 2 of KV secrets engine mounted by default, so will
# need these paths to grant permissions:
path "kssv/*" {
  capabilities = ["read", "list"]
}
EOF'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write auth/ldap/config \
    url="ldap://openldap" \
    userattr=uid \
    userdn="ou=people,dc=example,dc=org" \
    groupdn="ou=groups,dc=example,dc=org" \
    groupfilter="(|(memberUid={{.Username}})(member={{.UserDN}}))" \
    groupattr="cn" \
    binddn="cn=admin,dc=example,dc=org" \
    bindpass="admin"
'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write auth/ldap/groups/configserver policies=config-server-policy'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write auth/ldap/groups/kssv policies=kssv-policy'


#######TRANSIT###########

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault secrets enable transit'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write -f transit/keys/orders'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault policy write app-orders -<<EOF
path "transit/encrypt/orders" {
   capabilities = [ "update" ]
}
path "transit/decrypt/orders" {
   capabilities = [ "update" ]
}
EOF
'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault token create -policy=app-orders'

docker-compose exec vault sh -c 'apk add jq && export VAULT_ADDR="http://127.0.0.1:8201" && export APP_ORDER_TOKEN=$(vault token create -policy=app-orders -format=json | jq -r ".auth | .client_token") && export CIPHERTEXT=$(VAULT_TOKEN=$APP_ORDER_TOKEN vault write transit/encrypt/orders plaintext=$(echo "4111 1111 1111 1111"| base64) -format=json | jq -r ".data | .ciphertext") && VAULT_TOKEN=$APP_ORDER_TOKEN vault write transit/decrypt/orders ciphertext=$CIPHERTEXT -format=json | jq -r ".data | .plaintext" | base64 -d'


#docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && vault login -method=ldap username=PTSVC-IOTMC-KSSV'

# docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault auth enable userpass'

# docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write auth/userpass/users/PTSVC-IOTMC-KSSV policies=my-policy password=user123'

# docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && vault login -method=userpass username=PTSVC-IOTMC-KSSV password=user123'



docker-compose exec openldap sh -c 'ldapmodify -x -D "cn=admin,dc=example,dc=org" -w admin <<EOF
dn: ou=groups,dc=example,dc=org
changetype: add
objectClass: organizationalUnit
ou: groups

dn: ou=people,dc=example,dc=org
changetype: add
objectClass: organizationalUnit
ou: people

dn: cn=configserver,ou=groups,dc=example,dc=org
changetype: add
objectClass: top
objectClass: posixGroup
cn: configserver
gidNumber: 1001

dn: cn=kssv,ou=groups,dc=example,dc=org
changetype: add
objectClass: top
objectClass: posixGroup
cn: kssv
gidNumber: 1002

dn: uid=PTSVC-IOTMC-KSSV,ou=people,dc=example,dc=org
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: PTSVC-IOTMC-KSSV
sn: PTSVC-IOTMC-KSSV
uid: PTSVC-IOTMC-KSSV
userPassword: user123

dn: cn=kssv,ou=groups,dc=example,dc=org
changetype: modify
add: memberUid
memberUid: PTSVC-IOTMC-KSSV

EOF
'

### Generate KSSV Keystore
keytool -genseckey -alias 1007 -keyalg AES -keysize 128 -storetype JCEKS -keystore run/keystore.jceks -storepass changeit -keypass changeit

#Migrate
utils/migrate_kssv_keystore.sh -dev

###Ldap Mode
echo -n "user123" > run/password.txt

###AppRole Mode
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault policy write kssv-policy -<<EOF
# Read-only permission on secrets stored at 'kssv/data/dev'
path "kssv/data/dev" {
  capabilities = [ "read" ]
}
EOF
'

docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault auth enable approle'
docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write auth/approle/role/kssv-role token_policies="kssv-policy" \
    token_ttl=1h \
    token_max_ttl=4h'

role_id=$(docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault read auth/approle/role/kssv-role/role-id' | awk '/role_id/ {print $2}')
wrap_token=$(docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && export VAULT_TOKEN="00000000-0000-0000-0000-000000000000" && vault write -wrap-ttl=60s -force auth/approle/role/kssv-role/secret-id' | awk '/wrapping_token:/ {print $2}')

#secret_id=$(docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && VAULT_TOKEN='"${wrap_token}"' vault unwrap' | awk '/secret_id[^_]/ {print $2}')


# token=$(docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && vault write auth/approle/login role_id='"${role_id}"' \
#     secret_id='"${secret_id}" | awk '/token[^_]/ {print $2}')

#docker-compose exec vault sh -c 'export VAULT_ADDR="http://127.0.0.1:8201" && VAULT_TOKEN='"${token}"' vault kv get kssv/dev'

echo -n "${role_id}" > run/role_id.txt
#echo -n "${secret_id}" > run/secret_id.txt
echo -n "${wrap_token}" > run/secret_id.txt


sleep 10
env/dev/control-app.sh start

tests/test.sh -dev
