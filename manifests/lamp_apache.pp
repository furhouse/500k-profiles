class profiles::lamp_apache {
  
  $apache_port = hiera('profiles::lamp_apache::apache_port', '80')
  $apache_docroot = hiera('profiles::lamp_apache::apache_docroot', '/var/www/vhost')

  class { '::apache': 
    mpm_module => 'prefork',
  }

  include apache::mod::php

  apache::vhost { 'vhost.example.com':
    port    => $apache_port,
    docroot => $apache_docroot,
  }

}
