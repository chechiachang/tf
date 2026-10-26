module "vcn" {
  source = "github.com/oracle-terraform-modules/terraform-oci-vcn?ref=29f2a4d641428896b482d4c6d06a81627a925af4"

  compartment_id = oci_identity_compartment.this.id
  tenancy_id     = var.tenancy_ocid
  label_prefix   = "asre"
  vcn_name       = var.vcn_name
  vcn_dns_label  = "asrefree"
  vcn_cidrs      = [var.vcn_cidr]
  # Manage the default list below instead of either built-in preset.
  lockdown_default_seclist = null
  create_internet_gateway  = false
  create_nat_gateway       = true
  create_service_gateway   = false
  enable_ipv6              = false

  subnets = var.subnets
}
