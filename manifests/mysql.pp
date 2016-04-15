class profiles::mysql(
  Hash $databases = [],
) {
  
  $mysql_root_password = hiera('profiles::mysql::mysql_root_password', 'somepassword')
  
  class { 'mysql::server':
    root_password => $mysql_root_password,
  }
->
  class { 'mysql::bindings':
    php_enable => true,
  }
  
  create_resources('::mysql::db', $databases)
  
}