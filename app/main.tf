data "aws_eks_cluster" "cluster" {
  name = var.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_id
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}



resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "${var.name}-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name           = data.aws_eks_cluster.cluster.name
  fargate_profile_name   = "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnets.*.id

  selector {
    namespace = "default"
  }

  selector {
    namespace = "hello-world"
  }

  timeouts {
    create = "30m"
    delete = "60m"
  }
}

resource "kubernetes_namespace" "example" {
  metadata {
    labels = {
      app = "hello-world"
    }

    name = "hello-world"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "deployment-hello-world"
    namespace = "hello-world"
    labels    = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        container {
          image = "tutum/hello-world"
          name  = "hello-world"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [aws_eks_fargate_profile.main]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "service-hello-world"
    namespace = "hello-world"
  }
  spec {
    selector = {
      app = "hello-world"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.app]
}

resource "kubernetes_ingress" "app" {
  metadata {
    name      = "hello-world-ingress"
    namespace = "hello-world"
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = {
        "app" = "hello-world-ingress"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "service-hello-world"
            service_port = 80
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.app]
}