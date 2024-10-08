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

output "cluster_cidr" {
  description = "IPv4/IPv6 network CIDRs to use for pod IPs"
  value       = var.cluster_cidr
}

output "k3s_join_token" {
  sensitive   = true
  description = "Join token for the k3s cluster"
  value       = local.k3s_join_token
}

output "kube_api_server" {
  description = "Kubernetes API server address"
  value       = local.kube_apiserver_address
}

output "kubeconfig" {
  sensitive   = true
  description = "Kubeconfig"
  value       = local.k3s_kubeconfig
}
