terraform {
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# Подготовка провайдеров
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

  scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

# Используем этот источник данных для доступа к конфигурации провайдера GCP 
data "google_client_config" "client" {}

# Этот источник данных позволяет получить OpenID userinfo учетных данных
data "google_client_openid_userinfo" "terraform_user" {}

provider "kubernetes" {
  version = "~> 1.7.0"

  load_config_file       = false
  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
}

provider "helm" {
# Мы не устанавливаем Tiller автоматически, вместо этого используем Kubergrunt, поскольку он гораздо проще настраивает
# сертификаты TLS.  
  install_tiller = false
  enable_tls = true

  kubernetes {
    host                   = data.template_file.gke_host_endpoint.rendered
    token                  = data.template_file.access_token.rendered
    cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Разворачиваем CLUSTER GCP
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  source = "./modules/gke-cluster"

  name = var.cluster_name

  project  = var.project
  location = var.location
  network  = module.vpc_network.network

# Мы развертываем кластер в «общедоступной public» подсети, чтобы разрешить исходящий доступ в Интернет
  subnetwork = module.vpc_network.public_subnetwork

 # При создании приватного кластера необходимо определить 'master_ipv4_cidr_block' с размерностью подсети /28
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  # Делаем кластер приватным
  enable_private_nodes = "false"

  # Чтобы упростить, мы оставляем общедоступную конечную точку доступной. На prod рекомендуем
  # ограничить доступ только в пределах границы сети, требуя от пользователей использовать хост-бастион или VPN.
  disable_public_endpoint = "false"

  # При использовании private кластера настоятельно рекомендуется ограничить доступ к мастеру кластера.
  # Однако для целей тестирования мы разрешим весь входящий трафик.
  master_authorized_networks_config = [
    {
      cidr_blocks = [
        {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing"
        },
      ]
    },
  ]

  cluster_secondary_range_name = module.vpc_network.public_subnetwork_secondary_range_name
}

# ---------------------------------------------------------------------------------------------------------------------
# Создаем pool основной ноды 
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name     = var.pool_name
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "5"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      private-pools-example = "true"
    }

    tags = [
      module.vpc_network.private,
      "private-pool-example",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Создаем pool ноды services (git-lab, monitoring, loging)
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool_services" {
  provider = google-beta

  name     = "services"
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

  initial_node_count = "1"

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      private-pools-example = "true"
    }

    tags = [
      module.vpc_network.private,
      "private-pool-example",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Создание сервисного аккаунта
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  source = "./modules/gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
}

# ---------------------------------------------------------------------------------------------------------------------
# Создаем сеть кластера
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.2.1"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

# ---------------------------------------------------------------------------------------------------------------------
# Конфигурируем KUBECTL и RBAC ROLE разрешения, создаем учетки
# ---------------------------------------------------------------------------------------------------------------------

# настроить kubectl с учетными данными кластера GKE
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud beta container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project}"

    # Используйте переменные среды, чтобы изменить пути конфигурации kubectl
    environment = {
      KUBECONFIG = var.kubectl_config_path != "" ? var.kubectl_config_path : ""
    }
  }

  depends_on = [google_container_node_pool.node_pool]
}

# Создаем учетную запись для TILLER
resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = local.tiller_namespace
  }
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = data.google_client_openid_userinfo.terraform_user.email
    api_group = "rbac.authorization.k8s.io"
  }

  # Мы присваиваем статус администратора кластера Tiller ServiceAccount, чтобы мы могли развернуть что угодно в любом пространстве
  # имен, используя этот экземпляр Tiller для тестирования. В производстве вы можете использовать более ограниченную роль.
  subject {
    api_group = ""

    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata[0].name
    namespace = local.tiller_namespace
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Генерируем TLS сертификаты для использования TILLER
# kubergrunt будет генерировать сертификаты TLS и загружать их как секреты Kubernetes, которые затем могут быть 
# использованы Tiller.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "null_resource" "tiller_tls_certs" {
  provisioner "local-exec" {
    command = <<-EOF
      kubergrunt tls gen --ca --namespace kube-system --secret-name ${local.tls_ca_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=ca --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}

      kubergrunt tls gen --namespace ${local.tiller_namespace} --ca-secret-name ${local.tls_ca_secret_name} --ca-namespace kube-system --secret-name ${local.tls_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=server --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}
    EOF

    # Используйте переменные окружения для учетных данных во избежании утечки через логи
    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Разворачиваем TILLER в GKE кластере
# ---------------------------------------------------------------------------------------------------------------------

module "tiller" {
  source = "github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-tiller?ref=v0.5.0"

  tiller_tls_gen_method                    = "none"
  tiller_service_account_name              = kubernetes_service_account.tiller.metadata[0].name
  tiller_service_account_token_secret_name = kubernetes_service_account.tiller.default_secret_name
  tiller_tls_secret_name                   = local.tls_secret_name
  namespace                                = local.tiller_namespace
  tiller_image_version                     = local.tiller_version

  # Kubergrunt будет хранить закрытый ключ под ключом «tls.pem» в секретном ресурсе, доступном при монтировании в контейнер
  tiller_tls_key_file_name = "tls.pem"

  dependencies = [null_resource.tiller_tls_certs.id, kubernetes_cluster_role_binding.user.id]
}

# Ждем развертывания 
resource "null_resource" "wait_for_tiller" {
  provisioner "local-exec" {
    command = "kubergrunt helm wait-for-tiller --tiller-namespace ${local.tiller_namespace} --tiller-deployment-name ${module.tiller.deployment_name} --expected-tiller-version ${local.tiller_version} ${local.kubectl_auth_config}"

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Настраиваем HELM CLIENT
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "null_resource" "grant_and_configure_helm" {
  provisioner "local-exec" {
    command = <<-EOF
    kubergrunt helm grant --tiller-namespace ${local.tiller_namespace} --tls-subject-json '${jsonencode(var.client_tls_subject)}' --rbac-user ${data.google_client_openid_userinfo.terraform_user.email} ${local.kubectl_auth_config}

    kubergrunt helm configure --helm-home ${pathexpand("~/.helm")} --tiller-namespace ${local.tiller_namespace} --resource-namespace ${local.resource_namespace} --rbac-user ${data.google_client_openid_userinfo.terraform_user.email} ${local.kubectl_auth_config}
    EOF

    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }

  depends_on = [null_resource.wait_for_tiller]
}

locals {
  tiller_namespace = "kube-system"

  resource_namespace = "voip"

  tiller_version = "v2.11.0"

  tls_ca_secret_namespace = "kube-system"

  tls_ca_secret_name   = "${local.tiller_namespace}-namespace-tiller-ca-certs"
  tls_secret_name      = "tiller-certs"
  tls_algorithm_config = "--tls-private-key-algorithm ${var.private_key_algorithm} ${var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"}"

  kubectl_auth_config = "--kubectl-server-endpoint \"$KUBECTL_SERVER_ENDPOINT\" --kubectl-certificate-authority \"$KUBECTL_CA_DATA\" --kubectl-token \"$KUBECTL_TOKEN\""
}

data "template_file" "gke_host_endpoint" {
  template = module.gke_cluster.endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "cluster_ca_certificate" {
  template = module.gke_cluster.cluster_ca_certificate
}
