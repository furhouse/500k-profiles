class profiles::lamp_apache {
  
  $apache_port = hiera('profiles::lamp_apache::apache_port', '80')
 
  class { '::apache': 
    mpm_module => 'prefork',
  }

  include apache::mod::php
  
  include wordpress

  apache::vhost { 'localhost':
    port    => $apache_port,
    docroot => "${::wordpress::install_dir}/wordpress",
    manage_docroot => false,
    require => Class['wordpress'],
  }

}
