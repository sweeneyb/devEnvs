resource "random_id" "project" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    proj_id = var.proj_id
  }

  byte_length = 8
}

resource "google_compute_project_metadata" "ssh_key" {
  project = google_project.dev-project.project_id
  metadata = {
	ssh-keys = join(":", ["user", tls_private_key.ssh_key.public_key_openssh])
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "keyfile" {
    content     = tls_private_key.ssh_key.private_key_pem
    filename = "${path.module}/id_rsa"
}


data "google_billing_account" "acct" {
  display_name = "My Billing Account"
  open         = true
}

resource "google_project" "dev-project" {
  name       = "${var.proj_id}-${random_id.project.hex}"
  project_id = "${var.proj_id}-${random_id.project.hex}"
  billing_account = data.google_billing_account.acct.id
}

# something is odd here; i had to enable the compute api by hand
resource "google_project_service" "compute_api" {
  project = google_project.dev-project.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "iam_api" {
  project = google_project.dev-project.project_id
  service = "iam.googleapis.com"

  disable_dependent_services = true
}

data "template_file" "cloud-config" {
  template = file("cloud-init.tmpl")

}

resource "google_compute_instance" "vm" {
  name         = "dev-machine"
  project = google_project.dev-project.project_id
  machine_type = "e2-standard-2"
  zone         = "us-east1-b"


  boot_disk {
    initialize_params {
      type  = "pd-standard"
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
      size  = var.boot_disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    user-data                 = data.template_file.cloud-config.rendered
    #google-logging-enabled    = true
    #google-monitoring-enabled = true
  }

  depends_on = [
    google_project_service.compute_api
  ]
}

resource "google_compute_firewall" "dev-ports" {
  name    = "allow-dev-traffic"
  project = google_project.dev-project.project_id
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_project_service.compute_api
  ]
}


// OUTPUTS  
output "ip_addrs" { 
  value = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}

output "ssh_public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}


