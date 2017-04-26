class profiles::foreman_plugins {

  class { '::foreman::compute::libvirt': }
  class { '::foreman::compute::foreman_compute': }
  class { '::foreman::compute::ec2': }
  class { '::foreman::plugin::bootdisk': }
  class { '::foreman::plugin::hooks': }
  class { '::foreman::plugin::docker': }
  class { '::foreman::plugin::puppetdb':
    address           => hiera('profiles::foreman_plugins::puppetdb_address', undef),
    dashboard_address => hiera('profiles::foreman_plugins::puppetdb_dash_address', undef),
  }
  class { '::foreman::plugin::discovery':
    install_images => hiera('profiles::foreman_plugins::discovery_install_images', false),
  }

}
