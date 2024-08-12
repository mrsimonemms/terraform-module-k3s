# terraform-module-k3s

Build a highly-available k3s cluster with Terraform

<!-- toc -->

* [Requirements](#requirements)
* [Providers](#providers)
* [Resources](#resources)
* [Inputs](#inputs)
* [Outputs](#outputs)
* [Contributing](#contributing)
  * [Open in a container](#open-in-a-container)

<!-- Regenerate with "pre-commit run -a markdown-toc" -->

<!-- tocstop -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_ssh"></a> [ssh](#requirement\_ssh) | >= 2.7.0, < 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_ssh"></a> [ssh](#provider\_ssh) | 2.7.0 |

## Resources

| Name | Type |
|------|------|
| [ssh_resource.additional_managers](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.drain_managers](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.drain_workers](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.initial_manager](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_resource.install_workers](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/resource) | resource |
| [ssh_sensitive_resource.join_token](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/sensitive_resource) | resource |
| [ssh_sensitive_resource.kubeconfig](https://registry.terraform.io/providers/loafoe/ssh/latest/docs/resources/sensitive_resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_cidr"></a> [cluster\_cidr](#input\_cluster\_cidr) | IPv4/IPv6 network CIDRs to use for pod IPs | `string` | `"10.42.0.0/16"` | no |
| <a name="input_cluster_dns"></a> [cluster\_dns](#input\_cluster\_dns) | IPv4 Cluster IP for coredns service. Should be in your service-cidr range | `string` | `"10.43.0.10"` | no |
| <a name="input_cluster_domain"></a> [cluster\_domain](#input\_cluster\_domain) | Cluster's internal domain name | `string` | `"cluster.local"` | no |
| <a name="input_cluster_init"></a> [cluster\_init](#input\_cluster\_init) | Use embedded etcd | `bool` | `true` | no |
| <a name="input_context"></a> [context](#input\_context) | Name of the kubeconfig context | `string` | `"default"` | no |
| <a name="input_custom_global_config"></a> [custom\_global\_config](#input\_custom\_global\_config) | Override configuration for all nodes. This is merged with the generated configuration. | `any` | `{}` | no |
| <a name="input_custom_manager_config"></a> [custom\_manager\_config](#input\_custom\_manager\_config) | Override configuration for the managers. This is merged with the generated configuration. | `any` | `{}` | no |
| <a name="input_custom_worker_config"></a> [custom\_worker\_config](#input\_custom\_worker\_config) | Override configuration for the workers. This is merged with the generated configuration. | `any` | `{}` | no |
| <a name="input_disable_addons"></a> [disable\_addons](#input\_disable\_addons) | Add-ons to be disabled | `list(string)` | <pre>[<br>  "servicelb",<br>  "traefik"<br>]</pre> | no |
| <a name="input_disable_cloud_controller"></a> [disable\_cloud\_controller](#input\_disable\_cloud\_controller) | Disable k3s default cloud controller manager | `bool` | `true` | no |
| <a name="input_drain_timeout"></a> [drain\_timeout](#input\_drain\_timeout) | Node drain timeout | `string` | `"30s"` | no |
| <a name="input_flannel_backend"></a> [flannel\_backend](#input\_flannel\_backend) | Flannel backend | `string` | `"wireguard-native"` | no |
| <a name="input_install_workers"></a> [install\_workers](#input\_install\_workers) | Install the workers directly | `bool` | `true` | no |
| <a name="input_k3s_channel"></a> [k3s\_channel](#input\_k3s\_channel) | Download channel to use. Ignored if k3s\_version is set | `string` | `"stable"` | no |
| <a name="input_k3s_download_url"></a> [k3s\_download\_url](#input\_k3s\_download\_url) | URL to download K3s from | `string` | `"https://get.k3s.io"` | no |
| <a name="input_k3s_networking"></a> [k3s\_networking](#input\_k3s\_networking) | CNI plugin to use - can be "flannel", "cilium". Set to null to not use any preconfigured CNI. | `string` | `"flannel"` | no |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | Specific k3s version to install | `string` | `null` | no |
| <a name="input_kubelet_args"></a> [kubelet\_args](#input\_kubelet\_args) | Arguments to pass to kubelet | `list(string)` | `[]` | no |
| <a name="input_kubernetes_https_listen_port"></a> [kubernetes\_https\_listen\_port](#input\_kubernetes\_https\_listen\_port) | Port that the Kubernetes HTTPS API is hosted on | `number` | `6443` | no |
| <a name="input_manager_load_balancer_address"></a> [manager\_load\_balancer\_address](#input\_manager\_load\_balancer\_address) | Load balancer placed in front of manager nodes to provide a highly available manager cluster. This will be added to the TLS SAN list | `string` | `null` | no |
| <a name="input_managers"></a> [managers](#input\_managers) | Manager pool configuration | <pre>list(object({<br>    advertise-address = string           # Node's advertise address - a private IP is recommended. This will be added to the TLS San list<br>    node-external-ip  = string           # External IP for the node<br>    node-ip           = string           # Private IP for the node<br>    name              = optional(string) # Name of the server node - will be "manager-<count>" if left blank<br><br>    labels = optional(list(object({<br>      key   = string<br>      value = string<br>    })), [])<br><br>    taints = optional(list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    })), [])<br><br>    # Node's SSH connection details<br>    connection = object({<br>      agent       = optional(bool)<br>      host        = string<br>      password    = optional(string)<br>      private_key = optional(string)<br>      port        = optional(number)<br>      timeout     = optional(string, "5m")<br>      user        = optional(string)<br><br>      bastion_host        = optional(string)<br>      bastion_password    = optional(string)<br>      bastion_private_key = optional(string)<br>      bastion_port        = optional(number)<br>      bastion_user        = optional(string)<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_network_subnet"></a> [network\_subnet](#input\_network\_subnet) | Host's network subnet. Used to get network interface for the flannel-iface value | `string` | n/a | yes |
| <a name="input_schedule_workloads_on_manager_nodes"></a> [schedule\_workloads\_on\_manager\_nodes](#input\_schedule\_workloads\_on\_manager\_nodes) | Allow scheduling of workloads of manager nodes. | `bool` | `true` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | IPv4/IPv6 network CIDRs to use for service IPs | `string` | `"10.43.0.0/16"` | no |
| <a name="input_sudo"></a> [sudo](#input\_sudo) | Use sudo for local kubectl commands | `bool` | `true` | no |
| <a name="input_tls_san"></a> [tls\_san](#input\_tls\_san) | Additional TLS SANs to add to the generated certificate | `list(string)` | `[]` | no |
| <a name="input_workers"></a> [workers](#input\_workers) | Worker pool configuration | <pre>map(list(object({<br>    node-external-ip = string           # External IP for the node<br>    node-ip          = string           # Private IP for the node<br>    name             = optional(string) # Name of the server node - will be "<pool>-<count>" if left blank<br><br>    labels = optional(list(object({<br>      key   = string<br>      value = string<br>    })), [])<br><br>    taints = optional(list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    })), [])<br><br>    # Node's SSH connection details<br>    connection = object({<br>      agent       = optional(bool)<br>      host        = string<br>      password    = optional(string)<br>      private_key = optional(string)<br>      port        = optional(number)<br>      timeout     = optional(string, "5m")<br>      user        = optional(string)<br><br>      bastion_host        = optional(string)<br>      bastion_password    = optional(string)<br>      bastion_private_key = optional(string)<br>      bastion_port        = optional(number)<br>      bastion_user        = optional(string)<br>    })<br>  })))</pre> | `{}` | no |
| <a name="input_write_kubeconfig_mode"></a> [write\_kubeconfig\_mode](#input\_write\_kubeconfig\_mode) | Write kubeconfig for admin client to this file | `string` | `"0644"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_cidr"></a> [cluster\_cidr](#output\_cluster\_cidr) | IPv4/IPv6 network CIDRs to use for pod IPs |
| <a name="output_k3s_join_token"></a> [k3s\_join\_token](#output\_k3s\_join\_token) | Join token for the k3s cluster |
| <a name="output_kube_api_server"></a> [kube\_api\_server](#output\_kube\_api\_server) | Kubernetes API server address |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig |
<!-- END_TF_DOCS -->

## Contributing

Set the Terraform Cloud token to an environment variable called
`TF_TOKEN_app_terraform_io`. By default, this should be set in a file called
`.envrc`

### Open in a container

* [Open in a container](https://code.visualstudio.com/docs/devcontainers/containers)
