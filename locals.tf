# Copyright 2024 Simon Emms <simon@simonemms.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  additional_managers = slice(local.manager_pool, 1, length(local.manager_pool))
  initial_manager     = local.manager_pool[0]
  k3s_install_commands = concat(
    [
      # Copy the config
      "sudo mkdir -p /etc/rancher/k3s/config.yaml.d",
      "sudo mv /tmp/k3sconfig.yaml /etc/rancher/k3s/config.yaml",
    ],
    var.k3s_networking == "flannel" && var.network_subnet != null ? [
      "echo \"flannel-iface: $(ip route get ${cidrhost(var.network_subnet, 0)} | awk -F \"dev \" 'NR==1{split($2, a, \" \"); print a[1]}')\" | sudo tee -a /etc/rancher/k3s/config.yaml.d/flannel.yaml"
    ] : [],
    [
      # Install k3s
      format("curl -sfL %s | %s sh -", var.k3s_download_url, var.k3s_version != null ? "INSTALL_K3S_VERSION=${var.k3s_version}" : "INSTALL_K3S_CHANNEL=${var.k3s_channel}"),
      # Ensure k3s is running
      "sudo systemctl start k3s"
    ]
  )
  k3s_install_worker_commands = [
    # Copy the config
    "sudo mkdir -p /etc/rancher/k3s/config.yaml.d",
    "sudo mv /tmp/k3sconfig.yaml /etc/rancher/k3s/config.yaml",
    "curl -sfL ${var.k3s_download_url} | INSTALL_K3S_EXEC=\"agent\" sh -"
  ]
  k3s_join_token               = chomp(ssh_sensitive_resource.join_token.result)
  k3s_kubeconfig               = chomp(ssh_sensitive_resource.kubeconfig.result)
  kube_apiserver_address       = var.manager_load_balancer_address != null ? var.manager_load_balancer_address : local.initial_manager.node-external-ip
  kube_apiserver_https_address = "https://${local.kube_apiserver_address}:${var.kubernetes_https_listen_port}"
  kubectl_cmd                  = var.sudo ? "sudo kubectl" : "kubectl"
  kube_labels = {
    pool = "node.kubernetes.io/pool"
  }
  manager_base_config = merge(
    {
      cluster-cidr             = var.cluster_cidr
      cluster-domain           = var.cluster_domain
      cluster-dns              = var.cluster_dns
      cluster-init             = var.cluster_init
      disable                  = var.disable_addons
      disable-cloud-controller = var.disable_cloud_controller
      https-listen-port        = var.kubernetes_https_listen_port
      kubelet-arg              = var.kubelet_args
      service-cidr             = var.service_cidr
      tls-san = distinct(concat(
        var.manager_load_balancer_address != null ? [local.kube_apiserver_address] : flatten([for i in var.managers : [i.advertise-address, i.node-external-ip]]),
        var.tls_san
      ))
      write-kubeconfig-mode = var.write_kubeconfig_mode
    },
    var.k3s_networking == "flannel" ? {
      flannel-backend = var.flannel_backend
    } : {}
  )
  # Add in the default values for the manager pool
  manager_pool = [for i, node in var.managers : merge(
    node,
    {
      name = node.name != null ? node.name : "manager-${i}"
    }
  )]
  worker_base_config = {
    kubelet-arg = var.kubelet_args
    server      = local.kube_apiserver_https_address
    token       = local.k3s_join_token
  }
  # Add in the default values for the worker pools
  worker_pools = {
    for poolName, nodes in var.workers : poolName => [
      for i, node in nodes : merge(
        node,
        {
          name = node.name != null ? node.name : "${poolName}-${i}"
          labels = concat(
            try(node.labels, []),
            [
              {
                key   = local.kube_labels.pool
                value = poolName
              }
            ]
          )
        }
      )
    ]
  }
}
