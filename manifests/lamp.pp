# manage_dependencies is set to false because I've included the installation 
# of git into common.yaml

class profiles::lamp {

  package { 'python':
    ensure => installed,
  }

  class { '::letsencrypt':
    email               => hiera('le_email', "admin@${::fqdn}"),
    manage_dependencies => false,
    require             => Package['python'],
  }

  $letsencrypt_staging = hiera('le_staging', false)

  if $letsencrypt_staging {
    letsencrypt::certonly { "${::fqdn}":
      domains         => hiera_array('le_domains', []),
      additional_args => hiera_array('le_args', []),
      require         => Class['::letsencrypt'],
    }
  }
  else {
    letsencrypt::certonly { "${::fqdn}":
      domains => hiera_array('le_domains', []),
      require => Class['::letsencrypt'],
    }
  }

  class { '::apache':
    default_vhost => false,
    mpm_module    => 'prefork',
    require       => Letsencrypt::Certonly["${::fqdn}"],
  }

  class { '::apache::mod::php': }
  class { '::apache::mod::rewrite': }
  class { '::apache::mod::ssl': }

  class { '::mysql::server':
    root_password           => hiera('sqlrootpass', 'undef'),
    remove_default_accounts => true,
    package_name            => 'mysql-server-5.6',
    override_options        => {
      'mysqld' => {
        'table_definition_cache' => '50',
      },
    }
  }

  $sqldatabases = hiera_hash('sqldatabases', {})
  $sqlusers = hiera_hash('sqlusers', {})
  $sqlgrants = hiera_hash('sqlgrants', {})

  create_resources('mysql_database', $sqldatabases)
  create_resources('mysql_user', $sqlusers)
  create_resources('mysql_grant', $sqlgrants)

  $vhosts = hiera_hash('lamp_vhosts', {})

  create_resources('apache::vhost', $vhosts)

}
