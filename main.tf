variable "gcp_project" {
  type  = string
  description = "Project id for GCP project to which the dployment will be made"
  nullable = false
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
    ops = {
      source = "nanovms/ops"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = "us-east1"
  zone    = "us-east1-b"
}

provider "ops" {

}

resource "ops_images" "hello_rocket_image" {
  name        = "hello-rocket"
  elf         = "./hello-rocket"
  config      = "./ops.json"
  targetcloud = "gcp"
}

resource "random_id" "instance_id" {
  byte_length = 8
}

resource "google_storage_bucket" "images_bucket" {
  name          = "hello-rocket-terraform-images-${random_id.instance_id.hex}"
  location      = "us"
  force_destroy = true
}

resource "google_storage_bucket_object" "hello_rocket_raw_disk" {
  name   = "hello-rocket.tar.gz"
  source = ops_images.hello_rocket_image.path
  bucket = google_storage_bucket.images_bucket.name
}

resource "google_compute_image" "hello_rocket_image" {
  name = "hello-rocket-${random_id.instance_id.hex}"

  raw_disk {
    source = google_storage_bucket_object.hello_rocket_raw_disk.self_link
  }

  labels = {
    "createdby" = "ops"
  }
}

resource "google_compute_instance" "hello_rocket_instance" {
  name         = "hello-rocket"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = google_compute_image.hello_rocket_image.self_link
    }
  }

  labels = {
    "createdby" = "ops"
  }

  tags = ["hello-rocket"]

  network_interface {
    network = "default"
    access_config {}
  }

}

resource "google_compute_firewall" "hello_rocket_firewall" {
  name    = "hello-rocket-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  target_tags = ["hello-rocket"]

  source_ranges = ["0.0.0.0/0"]
}

output "image_path" {
  value = ops_images.hello_rocket_image.path
}

output "instance_ip" {
  value = google_compute_instance.hello_rocket_instance.network_interface[0].access_config[0].nat_ip
}

