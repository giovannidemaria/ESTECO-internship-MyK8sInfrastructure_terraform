terraform {
  backend "gcs" {
    bucket = "app-internships-my-apps-tfstate"
    prefix = "env/dev"
  }
}
