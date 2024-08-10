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

variable "cluster_cidr" {
  type        = string
  description = "IPv4/IPv6 network CIDRs to use for pod IPs"
  default     = "10.42.0.0/16"
}

variable "cluster_dns" {
  type        = string
  description = "IPv4 Cluster IP for coredns service. Should be in your service-cidr range"
  default     = "10.43.0.10"
}

variable "cluster_init" {
  type        = bool
  description = "Use embedded etcd"
  default     = true
}

variable "cluster_domain" {
  type        = string
  description = "Cluster's internal domain name"
  default     = "cluster.local"
}

variable "context" {
  type        = string
  description = "Name of the kubeconfig context"
  default     = "default"
}

variable "custom_global_config" {
  type        = any
  description = "Override configuration for all nodes. This is merged with the generated configuration."
  default     = {}
}

variable "custom_manager_config" {
  type        = any
  description = "Override configuration for the managers. This is merged with the generated configuration."
  default     = {}
}

variable "custom_worker_config" {
  type        = any
  description = "Override configuration for the workers. This is merged with the generated configuration."
  default     = {}
}

variable "disable_addons" {
  type        = list(string)
  description = "Add-ons to be disabled"
  default = [
    "servicelb",
    "traefik"
  ]

  validation {
    condition = alltrue([
      for d in var.disable_addons : contains([
        "local-storage",
        "metrics-server",
        "servicelb",
        "traefik"
      ], d)
    ])
    error_message = "Unknown value in disable_addons"
  }
}

variable "disable_cloud_controller" {
  type        = bool
  description = "Disable k3s default cloud controller manager"
  default     = true
}

variable "drain_timeout" {
  type        = string
  description = "Node drain timeout"
  default     = "30s"
}

variable "flannel_backend" {
  type        = string
  description = "Flannel backend"
  default     = "wireguard-native"
}

variable "install_workers" {
  type        = bool
  description = "Install the workers directly"
  default     = true
}

variable "k3s_channel" {
  type        = string
  description = "Download channel to use. Ignored if k3s_version is set"
  default     = "stable"
}

variable "k3s_download_url" {
  type        = string
  description = "URL to download K3s from"
  default     = "https://get.k3s.io"
}

variable "k3s_networking" {
  type        = string
  description = "CNI plugin to use - can be \"flannel\", \"cilium\". Set to null to not use any preconfigured CNI."
  default     = "flannel"
}

variable "k3s_version" {
  type        = string
  description = "Specific k3s version to install"
  default     = null
}

variable "kubelet_args" {
  type        = list(string)
  description = "Arguments to pass to kubelet"
  default     = []
}

variable "kubernetes_https_listen_port" {
  type        = number
  description = "Port that the Kubernetes HTTPS API is hosted on"
  default     = 6443
}

variable "managers" {
  type = list(object({
    advertise-address = string           # Node's advertise address - a private IP is recommended. This will be added to the TLS San list
    node-external-ip  = string           # External IP for the node
    node-ip           = string           # Private IP for the node
    name              = optional(string) # Name of the server node - will be "manager-<count>" if left blank

    labels = optional(list(object({
      key   = string
      value = string
    })), [])

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    # Node's SSH connection details
    connection = object({
      agent       = optional(bool)
      host        = string
      password    = optional(string)
      private_key = optional(string)
      port        = optional(number)
      timeout     = optional(string, "5m")
      user        = optional(string)

      bastion_host        = optional(string)
      bastion_password    = optional(string)
      bastion_private_key = optional(string)
      bastion_port        = optional(number)
      bastion_user        = optional(string)
    })
  }))
  description = "Manager pool configuration"
  default     = []

  validation {
    condition     = length(var.managers) > 0
    error_message = "One manager node must be provided."
  }

  validation {
    condition     = length(var.managers) % 2 == 1
    error_message = "Manager nodes must be an odd number."
  }
}

variable "manager_load_balancer_address" {
  type        = string
  description = "Load balancer placed in front of manager nodes to provide a highly available manager cluster. This will be added to the TLS SAN list"
  default     = null
}

variable "network_subnet" {
  type        = string
  description = "Host's network subnet. Used to get network interface for the flannel-iface value"
}

variable "service_cidr" {
  type        = string
  description = "IPv4/IPv6 network CIDRs to use for service IPs"
  default     = "10.43.0.0/16"
}

variable "schedule_workloads_on_manager_nodes" {
  type        = bool
  description = "Allow scheduling of workloads of manager nodes."
  default     = true
}

variable "sudo" {
  type        = bool
  description = "Use sudo for local kubectl commands"
  default     = true
}

variable "tls_san" {
  type        = list(string)
  description = "Additional TLS SANs to add to the generated certificate"
  default     = []
}

variable "workers" {
  type = map(list(object({
    node-external-ip = string           # External IP for the node
    node-ip          = string           # Private IP for the node
    name             = optional(string) # Name of the server node - will be "<pool>-<count>" if left blank

    labels = optional(list(object({
      key   = string
      value = string
    })), [])

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    # Node's SSH connection details
    connection = object({
      agent       = optional(bool)
      host        = string
      password    = optional(string)
      private_key = optional(string)
      port        = optional(number)
      timeout     = optional(string, "5m")
      user        = optional(string)

      bastion_host        = optional(string)
      bastion_password    = optional(string)
      bastion_private_key = optional(string)
      bastion_port        = optional(number)
      bastion_user        = optional(string)
    })
  })))
  description = "Worker pool configuration"
  default     = {}
}

variable "write_kubeconfig_mode" {
  type        = string
  description = "Write kubeconfig for admin client to this file"
  default     = "0644"
}
