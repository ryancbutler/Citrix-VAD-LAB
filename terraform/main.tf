provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_rp}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.vsphere_network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_folder" "folder" {
  path          = "Citrix-Lab"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "ddc" {
  name             = "${var.vm_ddc}${count.index + 1}"
  count            = 2
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = 2
  memory           = 4096
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    linked_clone = "${var.vsphere_linkedclones}"

    customize {
      windows_options {
        computer_name         = "${var.vm_ddc}${count.index + 1}"
        join_domain           = "${var.domain}"
        domain_admin_user     = "${var.domain_user}"
        domain_admin_password = "${var.domain_password}"
        time_zone             = "${var.vsphere_timezone}"
      }

      network_interface {}


    }
  }
}

resource "vsphere_virtual_machine" "storefront" {
  name             = "${var.vm_storefront}${count.index + 1}"
  count            = 2
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = 2
  memory           = 2048
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }


  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    linked_clone = "${var.vsphere_linkedclones}"

    customize {
      windows_options {
        computer_name         = "${var.vm_storefront}${count.index + 1}"
        join_domain           = "${var.domain}"
        domain_admin_user     = "${var.domain_user}"
        domain_admin_password = "${var.domain_password}"
        time_zone             = "${var.vsphere_timezone}"
      }

      network_interface {}

    }
  }
}

resource "vsphere_virtual_machine" "sql" {
  name             = "${var.vm_sql}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = 2
  memory           = 4096
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }


  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    linked_clone = "${var.vsphere_linkedclones}"

    customize {
      windows_options {
        computer_name         = "${var.vm_sql}"
        join_domain           = "${var.domain}"
        domain_admin_user     = "${var.domain_user}"
        domain_admin_password = "${var.domain_password}"
        time_zone             = "${var.vsphere_timezone}"
      }

      network_interface {}


    }
  }
}

resource "vsphere_virtual_machine" "vda" {
  name             = "${var.vm_vda}${count.index + 1}"
  count            = 1
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = 2
  memory           = 4096
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }


  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    linked_clone = "${var.vsphere_linkedclones}"

    customize {
      windows_options {
        computer_name         = "${var.vm_vda}${count.index + 1}"
        join_domain           = "${var.domain}"
        domain_admin_user     = "${var.domain_user}"
        domain_admin_password = "${var.domain_password}"
        time_zone             = "${var.vsphere_timezone}"
      }

      network_interface {}

    }
  }
}

# terraform {
#   backend "remote" {
#     organization = "TechDrabble"
#     workspaces {
#       name = "cvad-lab"
#     }
#   }
# }
