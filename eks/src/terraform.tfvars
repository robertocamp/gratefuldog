region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "gratefuldog"

stage = "dev"

name = "terraform"

kubernetes_version = "1.22"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t3.small","t3.medium"]

desired_size = 3

max_size = 5

min_size = 2

kubernetes_labels = {}

cluster_encryption_config_enabled = true

addons = [
  {
    addon_name               = "vpc-cni"
    addon_version            = null
    resolve_conflicts        = "NONE"
    service_account_role_arn = null
  }
]