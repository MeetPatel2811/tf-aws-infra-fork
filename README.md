# Instructions for setting up infrastructure using Terraform on AWS




This repository contains Terraform configurations for setting up and deploying a scalable, secure web application infrastructure on AWS using CI/CD workflows.

## Prerequisites
- Install Terraform: https://developer.hashicorp.com/terraform/install?product_intent=terraform
- AWS CLI installed and configured:
      GitHub repository with CI secrets set:
      AWS_ACCESS_KEY_ID_DEV, AWS_SECRET_ACCESS_KEY_DEV
      AWS_ACCESS_KEY_ID_DEMO, AWS_SECRET_ACCESS_KEY_DEMO
      PACKER_AMI_NAME

## Setup
1. Clone the Repository:
   ```bash
   git@github.com:git@github.com:Meet-CSYE-6225/tf-aws-infra.git
2. Run below commands:
    - terraform init
    - terraform plan
    - terraform apply
## SSL Certificate
-  aws acm import-certificate \  
  --certificate meet2811_me://meet2811_me.crt \      
  --private-key meet2811_me://private.key \      
  --certificate-chain meet2811_me://meet2811_me.ca_bundle.crt \  
  --region us-east-1
