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

resource "ssh_resource" "initial_manager" {
  file {
    content = yamlencode(merge(
      local.manager_base_config,
      {
        advertise-address = local.initial_manager.advertise-address
        node-external-ip  = local.initial_manager.node-external-ip
        node-ip           = local.initial_manager.node-ip
        node-name         = local.initial_manager.name
        node-label        = [for l in local.initial_manager.labels : "${l.key}=${l.value}"]
        node-taint = [for t in concat(
          var.schedule_workloads_on_manager_nodes ? [] : [
            {
              key    = "CriticalAddonsOnly"
              value  = "true"
              effect = "NoExecute"
            }
          ],
          local.initial_manager.taints
        ) : "${t.key}=${t.value}:${t.effect}"]
      },
      var.custom_manager_config,
      var.custom_global_config,
    ))
    destination = "/tmp/k3sconfig.yaml"
  }

  commands = concat(
    local.k3s_install_commands,
    [
      "until ${local.kubectl_cmd} get node ${local.initial_manager.name}; do sleep 1; done"
    ]
  )

  # Connection details
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

  triggers = {
    channel = var.k3s_channel
    version = var.k3s_version
  }
}

resource "ssh_sensitive_resource" "join_token" {
  commands = [
    "sudo cat /var/lib/rancher/k3s/server/token"
  ]

  # Connection details
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

  depends_on = [
    ssh_resource.initial_manager
  ]
}

resource "ssh_sensitive_resource" "kubeconfig" {
  commands = [
    format(
      "sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/%s/%s/' | sed 's/%s/%s/'",
      "127.0.0.1",
      local.kube_apiserver_address,
      "default",
      var.context
    )
  ]

  # Connection details
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

  depends_on = [
    ssh_resource.initial_manager
  ]
}

resource "ssh_resource" "additional_managers" {
  for_each = { for manager in local.additional_managers : manager.name => manager }

  file {
    content = yamlencode(merge(
      local.manager_base_config,
      {
        advertise-address = each.value.advertise-address
        node-external-ip  = each.value.node-external-ip
        node-ip           = each.value.node-ip
        node-label        = [for l in each.value.labels : "${l.key}=${l.value}"]
        node-name         = each.value.name
        node-taint = [for t in concat(
          var.schedule_workloads_on_manager_nodes ? [] : [
            {
              key    = "CriticalAddonsOnly"
              value  = "true"
              effect = "NoExecute"
            }
          ],
          each.value.taints
        ) : "${t.key}=${t.value}:${t.effect}"]
        server = local.kube_apiserver_https_address
        token  = local.k3s_join_token
      },
      var.custom_manager_config,
      var.custom_global_config,
    ))
    destination = "/tmp/k3sconfig.yaml"
  }

  commands = concat(
    local.k3s_install_commands,
    [
      "until ${local.kubectl_cmd} get node ${each.value.name}; do sleep 1; done"
    ]
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
}

resource "ssh_resource" "drain_managers" {
  # Don't run on the initial manager - no point as it's being destroyed
  for_each = { for manager in local.additional_managers : manager.name => manager }

  when = "destroy"

  commands = [
    "${local.kubectl_cmd} cordon ${each.key}", # Not really necessary, but belt-and-braces
    "${local.kubectl_cmd} drain ${each.key} --delete-local-data --force --ignore-daemonsets --timeout=${var.drain_timeout}",
    "${local.kubectl_cmd} delete node ${each.key} --force --timeout=${var.drain_timeout} || true"
  ]

  triggers = {
    node_name = each.key
  }

  # Connection details - connect to a manager node
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

  depends_on = [ssh_resource.install_workers]

  lifecycle {
    ignore_changes = [triggers]
  }
}
