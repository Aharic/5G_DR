# your Kubernetes cluster name here. Must be a valid hostname.
cluster_name = "occne"

# SSH key to use for access to nodes
public_key_path = "~/.ssh/id_rsa.pub"

# image to use for bastion, masters, standalone etcd instances, and nodes
image = "OracleLinux-7.5-x86_64"

# user on the nodes
ssh_user = "cloud-user"

# bastion nodes
number_of_bastions = 1
flavor_bastion = "570f9b64-6843-4d2e-832d-4f7e3ad1be60"

# k8s master/etcd nodes
# An odd number of nodes is required.
number_of_k8s_masters_no_floating_ip = 1
flavor_k8s_master = "0a28076b-19bd-4b69-af0a-f3324399434e"

# k8s nodes
number_of_k8s_nodes = 3
flavor_k8s_node = "7b23dd34-bd8d-418d-9905-69a7ae5c0c46"

# mysql ndb nodes
number_of_db_tier_management_nodes = 1
number_of_db_tier_data_nodes = 2
number_of_db_tier_sql_nodes = 2

flavor_db_tier_management_node = "4e371ba3-5cdb-4b89-bbb0-ebc02fd7665e"
flavor_db_tier_data_node = "1ba3666f-774c-49be-ae52-bffc97b0f8d3"
flavor_db_tier_sql_node = "0a28076b-19bd-4b69-af0a-f3324399434e"

# networking
network_name = "occne"
ntp_server = "10.75.171.2"
external_net = "1d25d5ea-77ca-4f56-b364-f53b09292e7b"
subnet_cidr = "192.168.200.0/22"
floatingip_pool = "ext-net2"
bastion_allowed_remote_ips = ["0.0.0.0/0"]
wait_for_floatingip = "true"
