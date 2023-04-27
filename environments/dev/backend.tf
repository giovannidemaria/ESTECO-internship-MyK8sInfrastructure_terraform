terraform {
  backend "gcs" {
    bucket = "app-internships-tfstate"
    prefix = "env/dev"
  }
}
