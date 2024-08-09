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
  global_ipv4_cidr = "0.0.0.0/0"
  global_ipv6_cidr = "::/0"
  k3s_manager_labels = merge(local.labels, {
    format(local.label_namespace, "type") = "manager"
  })
  k3s_worker_labels = merge(local.labels, {
    format(local.label_namespace, "type") = "worker"
  })
  # Convert pools into individual servers
  k3s_worker_pools = flatten([
    for w in var.k3s_worker_pools : [
      for n in range(w.count) :
      merge(
        w,
        {
          location = w.location != null ? w.location : var.location
          name     = "${w.name}-${n}"
          pool     = w.name
        }
      )
    ]
  ])
  kubernetes_api_port = 6443
  label_namespace     = "simonemms.com/%s"
  labels = {
    format(local.label_namespace, "name") = var.name
  }
  name_prefix     = "k3s-${var.name}"
  ssh_port        = 2244
  ssh_private_key = trimspace(tls_private_key.server.private_key_openssh)
  ssh_public_key  = trimspace(tls_private_key.server.public_key_openssh)
  ssh_user        = "k3s"
  user_data = templatefile("${path.module}/files/cloud-config.yaml", {
    sshPort   = local.ssh_port
    publicKey = hcloud_ssh_key.server.public_key
    user      = local.ssh_user
  })
}
