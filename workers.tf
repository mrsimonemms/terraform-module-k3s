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

resource "ssh_resource" "install_workers" {
  for_each = var.install_workers ? { for node in(flatten([for nodes in local.worker_pools : nodes])) : node.name => node } : {}

  file {
    content = yamlencode(merge(
      local.worker_base_config,
      {
        node-external-ip = each.value.node-external-ip
        node-ip          = each.value.node-ip
        node-name        = each.value.name
        node-label       = [for l in each.value.labels : "${l.key}=${l.value}"]
        node-taint       = [for t in each.value.taints : "${t.key}=${t.value}:${t.effect}"]
      },
      var.custom_worker_config,
      var.custom_global_config,
    ))
    destination = "/tmp/k3sconfig.yaml"
  }

  commands = concat(
    local.k3s_install_worker_commands,
  )

  # Connection details
  agent       = each.value.connection.agent
  host        = each.value.connection.host
  password    = each.value.connection.password
  private_key = each.value.connection.private_key
  port        = each.value.connection.port
  timeout     = each.value.connection.timeout
  user        = each.value.connection.user

  bastion_host        = each.value.connection.bastion_host
  bastion_password    = each.value.connection.bastion_password
  bastion_private_key = each.value.connection.bastion_private_key
  bastion_port        = each.value.connection.bastion_port
  bastion_user        = each.value.connection.bastion_user

  triggers = {
    channel = var.k3s_channel
    version = var.k3s_version
  }

  depends_on = [
    ssh_resource.initial_manager,
    ssh_resource.additional_managers,
  ]
}

resource "ssh_resource" "drain_workers" {
  for_each = { for node in(flatten([for nodes in local.worker_pools : nodes])) : node.name => node }

  when = "destroy"

  commands = [
    "${local.kubectl_cmd} cordon ${each.key}", # Not really necessary, but belt-and-braces
    "${local.kubectl_cmd} drain ${each.key} --delete-local-data --force --ignore-daemonsets --timeout=${var.drain_timeout}",
    "${local.kubectl_cmd} delete node ${each.key} --force --timeout=${var.drain_timeout}"
  ]

  triggers = {
    node_name = each.key
  }

  # Connection details - connect to a manager node
  agent       = local.initial_manager.connection.agent
  host        = local.initial_manager.connection.host
  password    = local.initial_manager.connection.password
  private_key = local.initial_manager.connection.private_key
  port        = local.initial_manager.connection.port
  timeout     = local.initial_manager.connection.timeout
  user        = local.initial_manager.connection.user

  bastion_host        = local.initial_manager.connection.bastion_host
  bastion_password    = local.initial_manager.connection.bastion_password
  bastion_private_key = local.initial_manager.connection.bastion_private_key
  bastion_port        = local.initial_manager.connection.bastion_port
  bastion_user        = local.initial_manager.connection.bastion_user

  depends_on = [ssh_resource.install_workers]

  lifecycle {
    ignore_changes = [triggers]
  }
}
