pid_file = "run/pidfile"
log_file = "run/"

vault {
  address = "http://127.0.0.1:8201/"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "approle" {
    config = {
      role_id_file_path = "run/role_id.txt"
      secret_id_file_path = "run/secret_id.txt"
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