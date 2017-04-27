class profiles::puppetserver {

  $jvm_heap_size = hiera('profiles::puppetserver::jvm_heap_size', '2g')

  class { '::puppet':
    server                      => true,
    agent                       => true,
    server_foreman              => hiera('profiles::puppetserver::server_foreman', false),
    server_ca                   => hiera('profiles::puppetserver::server_ca', false),
    ca_server                   => hiera('profiles::puppetserver::ca_server', undef),
    server_common_modules_path  => hiera_array('profiles::puppetserver::basemodulepath', []),
    server_environments         => hiera_array('profiles::puppetserver::environments', []),
    server_jvm_min_heap_size    => $jvm_heap_size,
    server_jvm_max_heap_size    => $jvm_heap_size,
    server_reports              => hiera('profiles::puppetserver::server_reports', 'store'),
    server_puppetdb_host        => hiera('profiles::puppetserver::puppetdb_host', undef),
    server_storeconfigs_backend => hiera('profiles::puppetserver::storeconfigs_backend', undef),
    server_parser               => hiera('profiles::puppetserver::server_parser', 'current'),
    listen                      => hiera('profiles::puppetserver::listen', false),
    show_diff                   => hiera('profiles::puppetserver::show_diff', false),
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

  class { '::r10k::webhook::config':
    use_mcollective  => hiera('profiles::puppetserver::r10k_hook_use_mco', false),
    user             => hiera('profiles::puppetserver::r10k_user', undef),
    pass             => hiera('profiles::puppetserver::r10k_pass', undef),
    public_key_path  => "/etc/puppetlabs/puppet/ssl/ca/signed/${facts['fqdn']}.pem",
    private_key_path => "/etc/puppetlabs/puppet/ssl/private_keys/${facts['fqdn']}.pem",
  }

  class { '::r10k::webhook':
    user  => hiera('profiles::puppetserver::r10k_hook_user', undef),
    group => hiera('profiles::puppetserver::r10k_hook_group', undef),
  }
  Class['r10k::webhook::config'] -> Class['r10k::webhook']

  $base_hierarchy = ['nodes/%{::fqdn}']
  $expand_hierarchy = hiera_array('profiles::puppetserver::hiera_hierarchy', [])
  $final_hierarchy = concat($base_hierarchy, $expand_hierarchy)

  class { '::hiera':
    datadir            => '/etc/puppetlabs/code/hieradata/%{::environment}',
    logger             => 'console',
    merge_behavior     => hiera('profiles::puppetserver::hiera_merge', 'deeper'),
    puppet_conf_manage => hiera('profiles::puppetserver::hiera_puppet_conf_manage', false),
    hierarchy          => $final_hierarchy,
  }

}
