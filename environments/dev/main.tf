terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
  backend "gcs" {
    bucket = "app-internships-my-apps-tfstate"
    prefix = "env/dev"
  }
}

data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../terraform.tfstate"
  }
}

# Retrieve GKE cluster information
provider "google" {
  project = data.terraform_remote_state.gke.outputs.project_id
  region  = data.terraform_remote_state.gke.outputs.region
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = data.terraform_remote_state.gke.outputs.kubernetes_cluster_name
  location = data.terraform_remote_state.gke.outputs.region
}

provider "kubernetes" {
  host = data.terraform_remote_state.gke.outputs.kubernetes_cluster_host

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "hello-py-srv-tf" {
    metadata {
      name = "hello-py-srv-tf"
      labels = {
        App = "helloPySrvTf"
      }
    }
  
    spec {
      replicas = 2
      selector {
        match_labels = {
          App = "helloPySrvTf"
        }
      }
      template {
        metadata {
          labels = {
            App = "helloPySrvTf"
          }
        }
        spec {
          container {
            image = "giovannidemaria/hello-py-srv:latest"
            name  = "hello-py-srv-tf"
  
            port {
              container_port = 80
            }
  
            resources {
              limits = {
                cpu    = "0.5"
                memory = "512Mi"
              }
              requests = {
                cpu    = "250m"
                memory = "50Mi"
              }
            }
          }
        }
      }
    }
  }
  
  resource "kubernetes_service" "hello-py-srv-tf" {
    metadata {
      name = "hello-py-srv-tf"
    }
    spec {
      selector = {
        App = kubernetes_deployment.hello-py-srv-tf.spec.0.template.0.metadata[0].labels.App
      }
      port {
        port        = 80
        target_port = 8080
      }
  
      type = "LoadBalancer"
    }
  }
  
  output "lb_ip2" {
    value = kubernetes_service.hello-py-srv-tf.status.0.load_balancer.0.ingress.0.ip
  }

  resource "kubernetes_deployment" "hello-go-srv-tf" {
  metadata {
    name = "hello-go-srv-tf"
    labels = {
      App = "hello-go-srv-tf"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "hello-go-srv-tf"
      }
    }
    template {
      metadata {
        labels = {
          App = "hello-go-srv-tf"
        }
      }
      spec {
        container {
          image = "giovannidemaria/hello-go-srv:latest"
          name  = "hello-go-srv-tf"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello-go-srv-tf" {
  metadata {
    name = "hello-go-srv-tf"
  }
  spec {
    selector = {
      App = kubernetes_deployment.hello-go-srv-tf.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

output "lb_ip3" {
  value = kubernetes_service.hello-go-srv-tf.status.0.load_balancer.0.ingress.0.ip
}
