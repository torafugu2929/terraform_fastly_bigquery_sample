resource "google_service_account" "fastly_bigquery_writer" {
  project      = var.gcp_project_id
  account_id   = "fastly-bigquery-writer"
  display_name = "BigQuery Writer for Fastly"
}

resource "google_service_account_iam_member" "fastly-logging_token_creator" {
  service_account_id = google_service_account.fastly_bigquery_writer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:fastly-logging@datalog-bulleit-9e86.iam.gserviceaccount.com"
}