# manage_dependencies is set to false because I've included the installation 
# of git into common.yaml

class profiles::lamp {

  $enable_letsencrypt = hiera('enable_letsencrypt', true)
  $letsencrypt_staging = hiera('le_staging', false)

  if $enable_letsencrypt {

    package { 'python':
      ensure => installed,
    }

    class { '::letsencrypt':
      email               => hiera('le_email', "admin@${::fqdn}"),
      manage_dependencies => false,
      require             => Package['python'],
    }

    if $letsencrypt_staging {
      letsencrypt::certonly { "${::fqdn}":
        domains         => hiera_array('le_domains', []),
        additional_args => hiera_array('le_args', []),
        require         => Class['::letsencrypt'],
      }
    }
    else {
      letsencrypt::certonly { "${::fqdn}":
        domains              => hiera_array('le_domains', []),
        require              => Class['::letsencrypt'],
        manage_cron          => true,
        cron_before_command  => 'service apache2 stop',
        cron_success_command => 'service apache2 reload',
      }
    }

    class { '::apache':
      default_vhost    => false,
      mpm_module       => 'prefork',
      server_tokens    => 'Prod',
      server_signature => 'Off',
      require          => Letsencrypt::Certonly["${::fqdn}"],
      log_formats      => {
        combined => '%h %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-Agent}i\" %D',
      },
    }
  }
  else {

    class { '::apache':
      default_vhost    => false,
      mpm_module       => 'prefork',
      server_tokens    => 'Prod',
      server_signature => 'Off',
      log_formats      => {
        combined       => '%h %l %u %t \"%r\" %s %b \"%{Referer}i\" \"%{User-Agent}i\" %D',
      },
    }
  }

  class { '::apache::mod::php': }
  class { '::apache::mod::rewrite': }
  class { '::apache::mod::ssl': }

  class { '::apache::mod::status':
    allow_from => hiera_array('apachestatus::from', []),
  }

  profiles::mod_gelf { 'default': }

  apache::mod { 'log_gelf':
    package => 'libapache2-mod-gelf',
  }

  class { '::mysql::server':
    root_password           => hiera('sqlrootpass', 'undef'),
    remove_default_accounts => true,
    package_name            => hiera('mysql_version', 'mysql-server-5.6'),
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
