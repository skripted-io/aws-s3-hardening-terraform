# teraform.tfvars

aws_region            = "us-east-1"
environment           = "staging"
service_name          = "my-app"
vpc_id                = "vpc-0123456789"
cidr_block            = "10.0.0.0/16"
private_subnet_ids    = ["subnet-0a1b2c3d4e4f","subnet-5g6h7i8j9k"]
private_rt_ids        = ["rtb-0a1b2c3d4e4f","rtb-5g6h7i8j9k"]