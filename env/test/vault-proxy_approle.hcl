pid_file = "./pidfile"
log_file = "/var/SP/m2muser/vault/"

vault {
  address = "https://secrets.vault.vodafone.com/"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    config = {
      role_id_file_path = "/opt/SP/apps/vault/role_id.txt"
      secret_id_file_path = "/opt/SP/apps/vault/secret_id.txt"
      secret_id_response_wrapping_path = "auth/approle/role/kssv-role/secret-id"
      remove_secret_id_file_after_reading = false
    }
 }
}

cache {
  // An empty cache stanza still enables caching
}

api_proxy {
  use_auto_auth_token = "force"
  enforce_consistency = "always"
}

listener "tcp" {
  address = "127.0.0.1:18100"
  tls_disable = true
}