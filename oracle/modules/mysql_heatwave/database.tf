resource "random_password" "admin" {
  length           = 24
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "oci_mysql_mysql_db_system" "this" {
  availability_domain     = var.availability_domain
  compartment_id          = var.compartment_id
  display_name            = "asre-mysql"
  shape_name              = "MySQL.Free"
  subnet_id               = var.subnet_id
  nsg_ids                 = [var.network_security_group_id]
  admin_username          = "asreadmin"
  admin_password          = random_password.admin.result
  data_storage_size_in_gb = 50
  is_highly_available     = false
}

resource "oci_mysql_heat_wave_cluster" "this" {
  db_system_id         = oci_mysql_mysql_db_system.this.id
  cluster_size         = 1
  is_lakehouse_enabled = false
  shape_name           = "HeatWave.Free"
}
