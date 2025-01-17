resource "google_bigquery_dataset" "fastly_access_log" {
  dataset_id = "fastly_access_log"
  project    = var.gcp_project_id

  default_partition_expiration_ms = 90 * 24 * 60 * 60 * 1000 # = 90日
  location                        = "asia-northeast1"

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "WRITER"
    user_by_email = google_service_account.fastly_bigquery_writer.email
  }
}

resource "google_bigquery_table" "sample_vcl" {
  dataset_id = google_bigquery_dataset.fastly_access_log.dataset_id
  project    = var.gcp_project_id
  table_id   = "sample_vcl"

  time_partitioning {
    field = "timestamp"
    type  = "HOUR"
  }

  schema = file("${path.module}/logging_bigquery/schema.json")
}
