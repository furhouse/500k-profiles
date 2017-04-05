class profiles::mysql {

  class { '::mysql::server':
    root_password           => hiera('profiles::mysql::mysql_rootpass', undef),
    remove_default_accounts => true,
    package_name            => hiera('profiles::mysql::mysql_version', 'mysql-server-5.6'),
    override_options        => {
      'mysqld' => {
        'table_definition_cache' => '50',
      },
    }
  }

  $sqldatabases = hiera_hash('profiles::mysql::sqldatabases', {})
  $sqlusers = hiera_hash('profiles::mysql::sqlusers', {})
  $sqlgrants = hiera_hash('profiles::mysql::sqlgrants', {})

  create_resources('mysql_database', $sqldatabases)
  create_resources('mysql_user', $sqlusers)
  create_resources('mysql_grant', $sqlgrants)

}
