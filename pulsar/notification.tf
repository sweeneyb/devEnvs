#resource "google_monitoring_notification_channel" "google_chat" {
#  display_name = "Test Notification Channel"
#  project      =  google_project.dev-project.id
#  type         = "google_chat"
#  labels = {
#    space_id = var.notification_gchat_space_id
#  }
#  force_delete = false
#}

#resource "google_monitoring_notification_channel" "basic" {
#  display_name = "Example Notification Channel"
#  type         = "email"
#  project      =  google_project.dev-project.id
#  labels = {
#    email_address = var.notification_email
#  }
#
#  depends_on = [
#    google_project_service.serviceusage, google_project_service.cloudresourcemanager
#  ]
#}

resource "google_billing_budget" "budget" {
  billing_account = data.google_billing_account.acct.id

  display_name    = "Billing Budget"
  amount {
    specified_amount {
      currency_code = "USD"
      units = "5"
    }
  }
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "FORECASTED_SPEND"
  }
  all_updates_rule {
    monitoring_notification_channels = [
#      google_monitoring_notification_channel.basic.id
    ]
    disable_default_iam_recipients = true
  }

  depends_on = [google_project_service.billingbudgets]
}