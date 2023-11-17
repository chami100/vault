# IoTVault



## Introduction

Code Repository with utils and scripts about Vault implementation. Using docker compose to make similar scenario like in test and prd, hashicorp vault integrated with ldap server.

Two KVs Engines:
* Config-Server - Where application secrets will be stored
* KSSV - Where kssv keys will be stored

Trial Engine:
* Transit - to try and experiment transit engine to replace kss engine in future

Using vault proxy with [ldap](env/dev/vault-proxy_ldap.hcl) method to abstract applications, and with [AppRole](env/dev/vault-proxy_approle.hcl) method, using wrap tokens

## Migrate kssv keystore
Script [migrate_kssv_keystore.sh](utils/migrate_kssv_keystore.sh) iterates over JCEKS keystore and put in Vault in kssv engine all read keys.

## Pre-requisites
* Install [Vault](https://developer.hashicorp.com/vault/docs/install)
* Docker
* Docker-compose
* awk

## Start

- Run the [download_extract.sh](utils/download_extract.sh), this will install vault cli
- Run the [starter.sh](starter.sh), this will start vault, openldap, create base configuration in vault and openldap, create JCEKS keystore, start Vault proxy, migrate keys and test
- Run the [stopper.sh](stopper.sh) to teardown everything

