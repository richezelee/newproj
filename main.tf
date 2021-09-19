terraform {
  required_providers {
    aws = {
      version = ">= 2.44"
    }
	kubernetes = {
	  version = "~> 1.10"
	}
  }

  required_version = ">= 1.0.7"
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

module "vpc" {
  source             = "./vpc"
  name               = var.name
  environment        = var.environment
  cidr               = var.cidr
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  availability_zones = var.availability_zones
}

module "eks" {
  source          = "./eks"
  name            = var.name
  environment     = var.environment
  region          = var.region
  k8s_version     = var.k8s_version
  vpc_id          = module.vpc.id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  kubeconfig_path = var.kubeconfig_path
}

module "ingress" {
  source       = "./ingress"
  name         = var.name
  environment  = var.environment
  region       = var.region
  vpc_id       = module.vpc.id
  cluster_id   = module.eks.cluster_id
}

module "app" {
  source          = "./app"
  name            = var.name
  environment     = var.environment
  cluster_id      = module.eks.cluster_id
    private_subnets = module.vpc.private_subnets
}