pid_file = "run/pidfile"
log_file = "run/"

vault {
  address = "http://127.0.0.1:8201/"
  retry {
    num_retries = 5
  }
}

auto_auth {
  method "ldap" {
    config = {
      username = "PTSVC-IOTMC-KSSV"
      password_file_path = "run/password.txt"
      remove_password_after_reading = false
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