class profiles::mysql {

  class { '::mysql::server':
    root_password           => hiera('profiles::mysql::mysql_rootpass', undef),
    remove_default_accounts => true,
    override_options        => {
      'mysqld' => {
        'table_definition_cache' => '50',
      },
    }
  }

  $sqldatabases = hiera_hash('profiles::mysql::sqldatabases', {})
  $sqlusers = hiera_hash('profiles::mysql::sqlusers', {})
  $sqlgrants = hiera_hash('profiles::mysql::sqlgrants', {})

  $sql_deps = { require => Class['::mysql::server'], }

  create_resources('mysql_database', $sqldatabases, $sql_deps)
  create_resources('mysql_user', $sqlusers, $sql_deps)
  create_resources('mysql_grant', $sqlgrants, $sql_deps)

}
