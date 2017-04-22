class profiles::puppet {

  $is_puppetmaster = hiera('is_puppetmaster', false)

  if !$is_puppetmaster {

    class { '::puppet':
      agent        => true,
      server       => false,
      puppetmaster => hiera('puppetmaster', undef),
      show_diff    => true,
      listen       => true,
    }
  }

  else {

    class { '::puppet':
      server                      => true,
      server_jvm_min_heap_size    => '1g',
      server_jvm_max_heap_size    => '1g',
      server_reports              => 'puppetdb,foreman',
      server_storeconfigs_backend => 'puppetdb',
      server_parser               => 'future',
      agent                       => true,
      listen                      => true,
      show_diff                   => true,
    }

    class { '::foreman':
      admin_password        => hiera('profiles::puppet::foreman_admin_pass', undef),
      db_password           => hiera('profiles::puppet::foreman_db_pass', undef),
      oauth_consumer_key    => hiera('profiles::puppet::foreman_oauth_consumer_key', undef),
      oauth_consumer_secret => hiera('profiles::puppet::foreman_oauth_consumer_secret', undef),
      logging_level         => 'info',
      loggers               => {
        app         => true,
        ldap        => true,
        permissions => true,
        sql         => false,
      },
    }

    class { '::foreman::compute::libvirt': }
    class { '::foreman::compute::foreman_compute': }
    class { '::foreman::compute::ec2': }
    class { '::foreman::plugin::bootdisk': }
    class { '::foreman::plugin::hooks': }
    class { '::foreman::plugin::docker': }
    class { '::foreman::plugin::puppetdb':
      address           => 'http://puppet:8080/pdb/cmd/v1',
      dashboard_address => 'http://puppet:8080/pdb/dashboard',
    }
    class { '::foreman::plugin::discovery':
      install_images => true,
    }

    class { '::foreman_proxy':
      oauth_consumer_key    => hiera('profiles::puppet::foreman_oauth_consumer_key', undef),
      oauth_consumer_secret => hiera('profiles::puppet::foreman_oauth_consumer_secret', undef),
      manage_sudoersd       => false,
      custom_repo           => true,
      puppetca              => true,
      puppetca_listen_on    => 'https',
      puppet                => true,
      puppet_listen_on      => 'https',
      tftp                  => true,
      tftp_listen_on        => 'https',
      tftp_servername       => "${::fqdn}",
      logs                  => true,
      logs_listen_on        => 'https',
      realm                 => true,
      realm_listen_on       => 'https',
      realm_principal       => hiera('profiles::puppet::foreman_proxy_realm_principal', undef),
      realm_provider        => 'freeipa',
      freeipa_remove_dns    => true,
      bmc                   => false,
      dhcp                  => false,
      dns                   => false,
      require               => Class['::foreman'],
    }

    class { '::hiera':
      datadir            => '/etc/puppetlabs/code/hieradata/%{::environment}',
      logger             => 'console',
      merge_behavior     => 'deeper',
      puppet_conf_manage => false,
      hierarchy          => [
        'nodes/%{::fqdn}',
        'common',
      ],
    }

    class { '::r10k':
      version           => '1.5.1',
      manage_modulepath => false,
      sources           => {
        'hiera4' => {
          'remote'  => hiera('modules_remote', undef),
          'basedir' => "${::settings::codedir}/environments",
          'prefix'  => false,
        },
        'hiera3' => {
          'remote'  => hiera('hiera_remote', undef),
          'basedir' => "${::settings::codedir}/hieradata",
          'prefix'  => false,
        }
      },
    }

  }

}
