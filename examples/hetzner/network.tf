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

resource "hcloud_network" "network" {
  name     = local.name_prefix
  ip_range = var.network_subnet
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = var.network_type
  network_zone = var.region
  ip_range     = var.network_subnet
}

resource "hcloud_firewall" "firewall" {
  name = "k3s-firewall-${var.name}"

  dynamic "rule" {
    for_each = [for each in [
      {
        description = "SSH port"
        port        = local.ssh_port
        source_ips  = var.firewall_allow_ssh_access
      },
      {
        description = "Allow ICMP (ping)"
        source_ips = [
          local.global_ipv4_cidr,
          local.global_ipv6_cidr,
        ]
        protocol = "icmp"
        port     = null
      },
      {
        description = "Allow all TCP traffic on private network"
        source_ips = [
          hcloud_network.network.ip_range
        ]
      },
      {
        description = "Allow all UDP traffic on private network"
        source_ips = [
          hcloud_network.network.ip_range
        ]
        protocol = "udp"
      },
      # Direct public access only allowed if single manager node
      {
        description = "Allow access to Kubernetes API"
        port        = local.kubernetes_api_port
        source_ips  = var.firewall_allow_api_access
        disabled    = var.k3s_manager_pool.count > 1
      }
    ] : each if lookup(each, "disabled", false) != true]

    content {
      description     = lookup(rule.value, "description", "")
      destination_ips = lookup(rule.value, "destination_ips", [])
      direction       = lookup(rule.value, "direction", "in")
      port            = lookup(rule.value, "port", "any")
      protocol        = lookup(rule.value, "protocol", "tcp")
      source_ips      = lookup(rule.value, "source_ips", [])
    }
  }

  apply_to {
    label_selector = join(",", [for key, value in local.labels : "${key}=${value}"])
  }
}
