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

resource "aws_iam_instance_profile" "ec2_eb_profile" {
  name = "tictactoe-ec2-profile"
  role = "LabRole"
}

# Create s3 bucket to store docker compose
resource "aws_s3_bucket" "app_bucket" {
  bucket = "tic-tac-toe-bucket-m4tth3wg"
  tags   = local.tags
}

# Create s3 object from the compressed docker run config

resource "aws_s3_object" "docker_compose_object" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "compose.yaml"
  source = "./compose.yaml"
  tags   = local.tags
}

# Create eb app
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "tic-tac-toe-app"
  description = "tic-tac-toe-app beanstalk deployment"
  tags        = local.tags
}

# Create eb version
resource "aws_elastic_beanstalk_application_version" "eb_version" {
  name        = var.app_version
  application = aws_elastic_beanstalk_application.eb_app.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.docker_compose_object.id
  tags        = local.tags
}

# Create eb environment
resource "aws_elastic_beanstalk_environment" "eb_env" {
  name        = "eb-env"
  application = aws_elastic_beanstalk_application.eb_app.name
  version_label = aws_elastic_beanstalk_application_version.eb_version.name
  solution_stack_name = "64bit Amazon Linux 2 v3.8.0 running Docker"
  tier                = "WebServer"
  cname_prefix        = var.cname_prefix
  tags                = local.tags

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_eb_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.security_group
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = var.public_subnet
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.min_instance_count
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_instance_count
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_DOMAIN"
    value     = "http://${var.cname_prefix}.${var.region}.elasticbeanstalk.com"
  }

  # listener

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = var.security_group
  }

  # backend listener

  setting {
    namespace = "aws:elb:listener:8080"
    name      = "InstancePort"
    value     = 8080
  }
}

