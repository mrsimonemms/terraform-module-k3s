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

module "k3s" {
  source = "../.."

  managers = [
    for i in hcloud_server.manager : {
      advertise-address = tolist(i.network)[0].ip
      node-external-ip  = i.ipv4_address
      node-ip           = tolist(i.network)[0].ip

      connection = {
        host        = i.ipv4_address
        port        = local.ssh_port
        private_key = local.ssh_private_key
        user        = local.ssh_user
      }
    }
  ]
  disable_addons = [
    "local-storage",
    "metrics-server",
    "servicelb",
    "traefik"
  ]
  kubelet_args                  = ["cloud-provider=external"]
  manager_load_balancer_address = var.k3s_manager_pool.count > 1 ? hcloud_load_balancer.k3s_manager[0].ipv4 : null
  network_subnet                = hcloud_network_subnet.subnet.ip_range

  depends_on = [
    ssh_resource.manager_ready,
    ssh_resource.workers_ready
  ]
}
