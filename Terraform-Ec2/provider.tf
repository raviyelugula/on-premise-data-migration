terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "jenkins-tf-state-files"
    key    = "opdm/terraform-ec2/state.tfstate"
    region = "us-east-1"
  }
}

# Configuring aws provider using shared creds file
provider "aws" {
  #shared_credentials_files = ["~/.aws/credentials"]
  #profile                  = "ravi_pc"
  region                   = "us-east-1"
}
