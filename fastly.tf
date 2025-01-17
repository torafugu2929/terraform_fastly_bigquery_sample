
locals {
  domain_name     = "example.com"
  backend_name    = "example-backend"
  backend_address = "example-backend.storage.googleapis.com"

  one_year = 31536000
}

resource "fastly_tls_subscription" "example_com" {
  domains               = [local.domain_name]
  certificate_authority = "certainly"
}

resource "fastly_service_vcl" "example" {
  name = "example"

  domain {
    name = local.domain_name
  }

  backend {
    address = local.backend_address
    name    = local.backend_name

    port              = 443
    override_host     = local.backend_address
    request_condition = ""
    ssl_cert_hostname = "storage.googleapis.com"
    ssl_sni_hostname  = "storage.googleapis.com"
  }

  // redirect http
  // https://docs.fastly.com/en/guides/forcing-an-https-redirect
  header {
    name        = "HSTS"
    type        = "response"
    action      = "set"
    destination = "http.Strict-Transport-Security"

    source   = "\"max-age=${local.one_year}\""
    priority = 20
  }

  // authenticate purge request
  // https://docs.fastly.com/en/guides/authenticating-api-purge-requests
  header {
    name        = "Fastly Purge"
    type        = "request"
    action      = "set"
    destination = "http.Fastly-Purge-Requires-Auth"
    source      = "\"1\""

    request_condition = "request is PURGE"
    priority          = 30
  }
  condition {
    name      = "request is PURGE"
    statement = "req.request == \"FASTLYPURGE\""
    type      = "REQUEST"
    priority  = 10
  }


  vcl {
    name    = "vcl_main"
    content = file("${path.module}/vcl/main.vcl")
    main    = true
  }


  logging_bigquery {
    name         = "logging_bigquery_main"
    project_id   = var.gcp_project_id
    dataset      = google_bigquery_dataset.fastly_access_log.dataset_id
    table        = google_bigquery_table.sample_vcl.table_id
    account_name = google_service_account.fastly_bigquery_writer.account_id
    format       = file("${path.module}/logging_bigquery/log_format.json")
  }
}
