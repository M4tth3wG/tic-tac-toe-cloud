terraform {
  required_providers {
    aws = { # Specify required AWS provider version
      source  = "hashicorp/aws"
      version = ">= 5.1"
    }
  }
  required_version = ">= 1.2.0" # Specify required Terraform version
}

provider "aws" {
  region = var.region # Set AWS provider configuration for the us-east-1 region.
}

# Create iam instance profile
resource "aws_iam_instance_profile" "ec2_eb_profile" {
  name = "tictactoe-ec2-profile"
  role = "LabRole" # Set role to default lab user role
}

# Create s3 bucket to store docker compose
resource "aws_s3_bucket" "app_bucket" {
  bucket = "tic-tac-toe-bucket-m4tth3wg"
  tags   = local.tags
}

# Create s3 object from the local compose.yaml file
resource "aws_s3_object" "docker_compose_object" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "compose.yaml"
  source = "./compose.yaml"
  tags   = local.tags
}

# Create elastic beanstalk application
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "tic-tac-toe-app"
  description = "tic-tac-toe-app beanstalk deployment"
  tags        = local.tags
}

# Create elastic beanstalk application version
resource "aws_elastic_beanstalk_application_version" "eb_version" {
  name        = var.app_version
  application = aws_elastic_beanstalk_application.eb_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.docker_compose_object.id
  tags        = local.tags
}

# Create elastic beanstalk environment
resource "aws_elastic_beanstalk_environment" "eb_env" {
  name        = "eb-env"
  application = aws_elastic_beanstalk_application.eb_app.name # Connect environment to application
  version_label = aws_elastic_beanstalk_application_version.eb_version.name # Connect application version to environment
  solution_stack_name = "64bit Amazon Linux 2 v3.8.0 running Docker" # Set solution stack to base environment off of
  tier                = "WebServer" # Set environment tier to support HTTP requests
  cname_prefix        = var.cname_prefix
  tags                = local.tags

  # Set iam instance profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_eb_profile.name
  }

  # Set instance type
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # Set security group
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.security_group
  }

  # Set vpc
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  # Set subnet
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = var.public_subnet
  }

  # Set elastic load balancer scheme to internet facing
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing" # Set load balancer to be publicly accessible 
  }

  # Configure instances to have public ip address
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  # Set environment type to LoadBalanced
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Set minium number of instances
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.min_instance_count
  }

  # Set maximum number of instances
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_instance_count
  }

  # Create environment variable storing application domain
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_DOMAIN"
    value     = "http://${var.cname_prefix}.${var.region}.elasticbeanstalk.com"
  }

  # Add security group to default load balancer
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = var.security_group
  }

  # Add listener to load balancer for api calls
  setting {
    namespace = "aws:elb:listener:8080"
    name      = "InstancePort"
    value     = 8080
  }
}

