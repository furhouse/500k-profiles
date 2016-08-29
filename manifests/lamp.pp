class profiles::lamp {

  class { '::apache':
    default_vhost => false,
    mpm_module    => 'prefork',
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

}
