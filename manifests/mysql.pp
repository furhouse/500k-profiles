class profiles::mysql {
  
  # Hiera lookups
  $mysql_root_password = hiera('profiles::mysql::mysql_root_password', 'somepassword')


  # # Configure mysql
  class { 'mysql::server':
    root_password => $mysql_root_password,
  }

  class { 'mysql::bindings':
    php_enable => true,
  }
}