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

resource "hcloud_load_balancer" "k3s_manager" {
  count = var.k3s_manager_pool.count > 1 ? 1 : 0

  name               = local.name_prefix
  load_balancer_type = var.k3s_manager_load_balancer_type
  network_zone       = var.region

  algorithm {
    type = var.k3s_manager_load_balancer_algorithm
  }

  labels = merge(local.labels, {})
}

resource "hcloud_load_balancer_network" "k3s_manager" {
  count = var.k3s_manager_pool.count > 1 ? 1 : 0

  load_balancer_id = hcloud_load_balancer.k3s_manager[count.index].id
  network_id       = hcloud_network.network.id

  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "hcloud_load_balancer_service" "k3s_manager" {
  count = var.k3s_manager_pool.count > 1 ? 1 : 0

  load_balancer_id = hcloud_load_balancer.k3s_manager[count.index].id
  protocol         = "tcp"
  listen_port      = local.kubernetes_api_port
  destination_port = local.kubernetes_api_port
}

resource "hcloud_load_balancer_target" "k3s_manager" {
  count = var.k3s_manager_pool.count > 1 ? 1 : 0

  load_balancer_id = hcloud_load_balancer.k3s_manager[count.index].id
  type             = "label_selector"
  label_selector   = join(",", [for key, value in local.k3s_manager_labels : "${key}=${value}"])
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.k3s_manager
  ]
}
