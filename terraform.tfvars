region  = "us-east-1"
project = "Demo"
env     = "dev"
app     = "app"

vpc_cidr              = "10.0.0.0/16"
create_nat            = true
create_private_subnet = true
create_db_subnet      = true

enable_ekscluster_logs = false