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

output "k3s_join_token" {
  sensitive   = true
  description = "Join token for the k3s cluster"
  value       = module.k3s.k3s_join_token
}

output "kubeconfig" {
  sensitive   = true
  description = "Kubeconfig"
  value       = module.k3s.kubeconfig
}

output "pools" {
  description = "Servers created"
  value = merge(
    {
      managers : [
        for m in hcloud_server.manager : {
          name         = m.name
          ipv4_address = m.ipv4_address
          ipv6_address = m.ipv6_address
        }
      ]
    },
    {
      for i, w in local.k3s_worker_pools : w.pool => {
        name         = hcloud_server.workers[i].name
        ipv4_address = hcloud_server.workers[i].ipv4_address
        ipv6_address = hcloud_server.workers[i].ipv6_address
      }...
    }
  )
}

output "ssh_port" {
  description = "SSH port for server"
  value       = local.ssh_port
}

output "ssh_private_key" {
  sensitive   = true
  description = "Private SSH key"
  value       = local.ssh_private_key
}

output "ssh_public_key" {
  description = "Public SSH key"
  value       = local.ssh_public_key
}

output "ssh_user" {
  description = "SSH user for server"
  value       = local.ssh_user
}
