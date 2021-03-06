// Mandatory variables for terracumber
variable "URL_PREFIX" {
  type = "string"
  default = "https://ci.suse.de/view/Manager/view/Manager-4.1/job/manager-4.1-qam-setup-cucumber"
}

// Not really used as this is for --runall parameter, and we run cucumber step by step
variable "CUCUMBER_COMMAND" {
  type = "string"
  default = "export PRODUCT='SUSE-Manager' && run-testsuite"
}

variable "CUCUMBER_GITREPO" {
  type = "string"
  default = "https://github.com/SUSE/spacewalk.git"
}

variable "CUCUMBER_BRANCH" {
  type = "string"
  default = "Manager-4.1"
}

variable "CUCUMBER_RESULTS" {
  type = "string"
  default = "/root/spacewalk/testsuite"
}

variable "MAIL_SUBJECT" {
  type = "string"
  default = "Results 4.1 QAM $status: $tests scenarios ($failures failed, $errors errors, $skipped skipped, $passed passed)"
}

variable "MAIL_TEMPLATE" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins.txt"
}

variable "MAIL_SUBJECT_ENV_FAIL" {
  type = "string"
  default = "Results 4.1 QAM: Environment setup failed"
}

variable "MAIL_TEMPLATE_ENV_FAIL" {
  type = "string"
  default = "../mail_templates/mail-template-jenkins-env-fail.txt"
}

variable "MAIL_FROM" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

variable "MAIL_TO" {
  type = "string"
  default = "galaxy-ci@suse.de"
}

// sumaform specific variables
variable "SCC_USER" {
  type = "string"
}

variable "SCC_PASSWORD" {
  type = "string"
}

variable "GIT_USER" {
  type = "string"
  default = null // Not needed for master, as it is public
}

variable "GIT_PASSWORD" {
  type = "string"
  default = null // Not needed for master, as it is public
}

provider "libvirt" {
  uri = "qemu+tcp://classic176.qa.prv.suse.net/system"
}

provider "libvirt" {
  alias = "classic179"
  uri = "qemu+tcp://classic179.qa.prv.suse.net/system"
}

provider "libvirt" {
  alias = "classic181"
  uri = "qemu+tcp://classic181.qa.prv.suse.net/system"
}

module "base" {
  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-40-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = ["sles15", "sles15sp1", "sles15sp2", "opensuse150"]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}

module "base2" {
  providers = {
    libvirt = libvirt.classic179
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-40-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = ["sles11sp4", "sles12sp4", "sles15", "sles15sp1"]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}

module "base3" {
  providers = {
    libvirt = libvirt.classic181
  }

  source = "./modules/base"

  cc_username = var.SCC_USER
  cc_password = var.SCC_PASSWORD
  name_prefix = "qam-pip-40-"
  use_avahi   = false
  domain      = "qa.prv.suse.net"
  images      = ["sles15sp1", "ubuntu1804"]

  mirror = "minima-mirror.qa.prv.suse.net"
  use_mirror_images = true

  testsuite          = true

  provider_settings = {
    pool        = "default"
    bridge      = "br0"
    additional_network = "192.168.40.0/24"
  }
}

module "srv" {
  source             = "./modules/server"
  base_configuration = module.base.configuration
  product_version    = "head"
  name               = "srv"
  provider_settings = {
    mac                = "52:54:00:F6:5D:E8"
    memory             = 40960
    vcpu               = 6
    data_pool            = "default"
  }

  repository_disk_size = 750

  auto_accept                    = false
  monitored                      = true
  disable_firewall               = false
  allow_postgres_connections     = false
  skip_changelog_import          = false
  browser_side_less              = false
  create_first_user              = false
  mgr_sync_autologin             = false
  create_sample_channel          = false
  create_sample_activation_key   = false
  create_sample_bootstrap_script = false
  publish_private_ssl_key        = false
  use_os_released_updates        = true
  disable_download_tokens        = false
  ssh_key_path                   = "./salt/controller/id_rsa.pub"
  from_email                     = "root@suse.de"

  //srv_additional_repos

}

module "pxy" {
  source             = "./modules/proxy"
  base_configuration = module.base.configuration
  product_version    = "head"
  name               = "pxy"
  provider_settings = {
    mac                = "52:54:00:F2:4D:7A"
    memory             = 4096
  }

  server_configuration = {
    hostname = "qam-pip-40-srv.qa.prv.suse.net"
    username = "admin"
    password = "admin"
  }
  auto_register             = false
  auto_connect_to_master    = false
  download_private_ssl_key  = false
  auto_configure            = false
  generate_bootstrap_script = false
  publish_private_ssl_key   = false
  use_os_released_updates   = true
  ssh_key_path              = "./salt/controller/id_rsa.pub"

}

module "cli-sles12sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "cli-sles12sp4"
  image              = "sles12sp4"
  provider_settings = {
    mac                = "52:54:00:0E:F8:ED"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "cli-sles11sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "cli-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:66:70:7B"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "cli-sles15" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/client"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "cli-sles15"
  image              = "sles15"
  provider_settings = {
    mac                = "52:54:00:06:F2:85"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "cli-sles15sp1" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/client"
  base_configuration = module.base3.configuration
  product_version    = "4.0-released"
  name               = "cli-sles15sp1"
  image              = "sles15sp1"
  provider_settings = {
    mac                = "52:54:00:BA:1D:11"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_register           = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

//module "cli-centos7" {
//  source             = "./modules/client"
//  base_configuration = module.base.configuration
//  product_version    = "4.0-released"
//  name               = "cli-centos7"
//  image              = "centos7"
//  provider_settings = {
//    mac                = "52:54:00:72:41:8A"
//  }
//  memory             = 2048
//
//  server_configuration = {
//    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
//  }
//  auto_register = false
//  use_os_released_updates = false
//  ssh_key_path  = "./salt/controller/id_rsa.pub"
//}

//module "cli-centos6" {
//  source = "./modules/client"
//  base_configuration = module.base.configuration
//  product_version = "4.0-released"
//  name = "cli-centos6"
//  image = "centos6"
//  mac = "52:54:00:BA:ED:61"
//  memory             = 2048
//  use_os_released_updates = false
//  server_configuration =  { hostname = "qam-pip-40-pxy.qa.prv.suse.net" }
//  ssh_key_path = "./salt/controller/id_rsa.pub"
//}

module "min-sles12sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "min-sles12sp4"
  image              = "sles12sp4"
  provider_settings = {
    mac                = "52:54:00:B2:49:5C"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "min-sles11sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "min-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:02:C8:20"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "min-sles15" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/minion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "min-sles15"
  image              = "sles15"
  provider_settings = {
    mac                = "52:54:00:DA:C7:79"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "min-sles15sp1" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.0-released"
  name               = "min-sles15sp1"
  image              = "sles15sp1"
  provider_settings = {
    mac                = "52:54:00:72:E5:BE"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master  = false
  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

//module "min-centos7" {
//  source             = "./modules/minion"
//  base_configuration = module.base.configuration
//  product_version    = "4.0-released"
//  name               = "min-centos7"
//  image              = "centos7"
//  provider_settings = {
//    mac                = "52:54:00:92:F9:D6"
//  memory             = 2048
//  server_configuration = {
//    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
//  }
//  auto_connect_to_master = false
//  use_os_released_updates = false
//  ssh_key_path           = "./salt/controller/id_rsa.pub"
//}

//module "min-centos6" {
//  source = "./modules/minion"
//  base_configuration = module.base.configuration
//  product_version = "4.0-released"
//  name = "min-centos6"
//  image = "centos6"
//  mac = "52:54:00:7A:13:48"
//  memory             = 2048
//  server_configuration =  { hostname = "qam-pip-40-pxy.qa.prv.suse.net" }
//  auto_connect_to_master = false
//  use_os_released_updates = false
//  ssh_key_path = "./salt/controller/id_rsa.pub"
//}

module "min-ubuntu1804" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/minion"
  base_configuration = module.base3.configuration
  product_version    = "4.0-released"
  name               = "min-ubuntu1804"
  image              = "ubuntu1804"
  provider_settings = {
    mac                = "52:54:00:D2:5E:EC"
    memory             = 2048
  }

  server_configuration = {
    hostname = "qam-pip-40-pxy.qa.prv.suse.net"
  }
  auto_connect_to_master = false
  use_os_released_updates = false
  ssh_key_path           = "./salt/controller/id_rsa.pub"
}

//module "min-ubuntu1604" {
//  source = "./modules/minion"
//  base_configuration = module.base.configuration
//  product_version = "4.0-released"
//  name = "min-ubuntu1604"
//  image = "ubuntu1604"
//  mac = "52:54:00:12:33:D8"
//  memory             = 2048
//  server_configuration =  { hostname =  "qam-pip-40-pxy.qa.prv.suse.net" }
//  auto_connect_to_master = false
//  use_os_released_updates = false
//  ssh_key_path = "./salt/controller/id_rsa.pub"
//}

module "minssh-sles12sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  provider_settings = {
    mac                = "52:54:00:DA:AD:B0"
    memory             = 2048
  }
  name               = "minssh-sles12sp4"
  image              = "sles12sp4"

  use_os_released_updates = false
  ssh_key_path = "./salt/controller/id_rsa.pub"
  gpg_keys     = ["default/gpg_keys/galaxy.key"]
}

module "minssh-sles11sp4" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "minssh-sles11sp4"
  image              = "sles11sp4"
  provider_settings = {
    mac                = "52:54:00:3A:0D:F9"
    memory             = 2048
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "minssh-sles15" {
  providers = {
    libvirt = libvirt.classic179
  }
  source             = "./modules/sshminion"
  base_configuration = module.base2.configuration
  product_version    = "4.0-released"
  name               = "minssh-sles15"
  image              = "sles15"
  provider_settings = {
    mac                = "52:54:00:62:D7:5D"
    memory             = 2048
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

module "minssh-sles15sp1" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.0-released"
  name               = "minssh-sles15sp1"
  image              = "sles15sp1"
  provider_settings = {
    mac                = "52:54:00:26:7C:DE"
    memory             = 2048
  }

  use_os_released_updates = false
  ssh_key_path            = "./salt/controller/id_rsa.pub"
}

//module "minssh-centos7" {
//  source             = "./modules/sshminion"
//  base_configuration = module.base.configuration
//  product_version    = "4.0-released"
//  name               = "minssh-centos7"
//  image              = "centos7"
//  provider_settings = {
//    mac                = "52:54:00:EA:AA:42"
//  memory             = 2048
//  use_os_released_updates = false
//  ssh_key_path = "./salt/controller/id_rsa.pub"
//}

//module "minssh-centos6" {
//  source = "./modules/sshminion"
//  base_configuration = module.base.configuration
//  product_version    = "4.0-released"
//  name = "minssh-centos6"
//  image = "centos6"
//  memory             = 2048
//  mac = "52:54:00:96:6B:AC"
//  use_os_released_updates = false
//  ssh_key_path = "./salt/controller/id_rsa.pub"
//}

module "minssh-ubuntu1804" {
  providers = {
    libvirt = libvirt.classic181
  }
  source             = "./modules/sshminion"
  base_configuration = module.base3.configuration
  product_version    = "4.0-released"
  name               = "minssh-ubuntu1804"
  image              = "ubuntu1804"
  provider_settings = {
    mac                = "52:54:00:8E:00:5A"
    memory             = 2048
  }
  use_os_released_updates = false
  ssh_key_path       = "./salt/controller/id_rsa.pub"
}

//module "minssh-ubuntu1604" {
//  source = "./modules/sshminion"
//  base_configuration = module.base.configuration
//  product_version    = "4.0-released"
//  name = "minssh-ubuntu1604"
//  image = "ubuntu1604"
//  mac = "52:54:00:CE:FE:C8"
//  memory             = 2048
//  use_os_released_updates = false
//  ssh_key_path = "./salt/controller/id_rsa.pub"
// }


module "ctl" {
  source             = "./modules/controller"
  base_configuration = module.base.configuration
  name               = "ctl"
  provider_settings = {
    mac                = "52:54:00:B2:CF:9B"
    memory             = 16384
    vcpu               = 6
  }

  // Cucumber repository configuration for the controller
  git_username = var.GIT_USER
  git_password = var.GIT_PASSWORD
  git_repo     = var.CUCUMBER_GITREPO
  branch       = var.CUCUMBER_BRANCH

  server_configuration = module.srv.configuration
  proxy_configuration  = module.pxy.configuration

  //  centos6_minion_configuration = module.min-centos6.configuration
  //  centos6_sshminion_configuration = module.minssh-centos6.configuration
  //  centos6_client_configuration = module.cli-centos6.configuration

  //  centos7_minion_configuration    = module.min-centos7.configuration
  //  centos7_sshminion_configuration = module.minssh-centos7.configuration
  //  centos7_client_configuration    = module.cli-centos7.configuration

  sle11sp4_minion_configuration    = module.min-sles11sp4.configuration
  sle11sp4_sshminion_configuration = module.minssh-sles11sp4.configuration
  sle11sp4_client_configuration    = module.cli-sles11sp4.configuration

  sle12sp4_minion_configuration    = module.min-sles12sp4.configuration
  sle12sp4_sshminion_configuration = module.minssh-sles12sp4.configuration
  sle12sp4_client_configuration    = module.cli-sles12sp4.configuration

  minion_configuration    = module.min-sles12sp4.configuration
  sshminion_configuration = module.minssh-sles12sp4.configuration
  client_configuration    = module.cli-sles12sp4.configuration

  sle15_minion_configuration    = module.min-sles15.configuration
  sle15_sshminion_configuration = module.minssh-sles15.configuration
  sle15_client_configuration    = module.cli-sles15.configuration

  sle15sp1_minion_configuration    = module.min-sles15sp1.configuration
  sle15sp1_sshminion_configuration = module.minssh-sles15sp1.configuration
  sle15sp1_client_configuration    = module.cli-sles15sp1.configuration

  //  ubuntu1604_minion_configuration = module.min-ubuntu1604.configuration
  //  ubuntu1604_sshminion_configuration = module.minssh-ubuntu1604.configuration

  ubuntu1804_minion_configuration = module.min-ubuntu1804.configuration
  ubuntu1804_sshminion_configuration = module.minssh-ubuntu1804.configuration
}

output "configuration" {
  value = {
    ctl = module.ctl.configuration
  }
}
