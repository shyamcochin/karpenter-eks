terraform {
  backend "s3" {
    bucket         = "mytest-terraform-state-bucket"  # Your S3 bucket name
    key            = "terraform/state.tfstate"        # Path to the state file in the bucket
    region         = "us-east-1"                      # Your AWS region
    dynamodb_table = "terraform-lock-table"           # Optional: DynamoDB table for locking
    encrypt        = true                             # Optional: Enable server-side encryption
  }
}
