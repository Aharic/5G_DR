# your Kubernetes cluster name here. Must be a valid hostname.
cluster_name = "vzw2"

use_floating_ip = true

# SSH key to use for access to nodes
public_key_path = "~/.ssh/id_rsa.pub"

# image to use for bastion, masters, standalone etcd instances, and nodes
image = "OracleLinux-7.5-x86_64"

# user on the nodes
ssh_user = "cloud-user"

# bastion nodes
number_of_bastions = 1
flavor_bastion = "dsrtac.cne.bastion"

# k8s master/etcd nodes
# An odd number of nodes is required.
number_of_k8s_masters_no_floating_ip = 1
flavor_k8s_master = "dsrtac.cne.db.sql.small"

# k8s nodes
number_of_k8s_nodes = 3
flavor_k8s_node = "dsrtac.cne.k8s.worker.large.disk100-custom"

# mysql ndb nodes
number_of_db_tier_management_nodes = 1
number_of_db_tier_data_nodes = 2
number_of_db_tier_sql_nodes = 2

flavor_db_tier_management_node = "DB-mgmt"
flavor_db_tier_data_node = "dsrtac.cne.db.data.small"
flavor_db_tier_sql_node = "dsrtac.cne.db.sql.small"

# networking
network_name = "vzw2"
ntp_server = "10.75.141.194"
external_net = "1d25d5ea-77ca-4f56-b364-f53b09292e7b"
subnet_cidr = "192.168.200.0/22"
floatingip_pool = "ext-net2"
bastion_allowed_remote_ips = ["0.0.0.0/0"]
wait_for_floatingip = "true"
