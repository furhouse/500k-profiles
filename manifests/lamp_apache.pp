class profiles::lamp_apache {
  # Hiera lookups
  $apache_port = hiera('profiles::apache::apache_port', '80')
  $apache_docroot = hiera('profiles::apache::apache_docroot', '/var/www/vhost')

  class { 'apache': }
  include apache::mod::php

  apache::vhost { 'vhost.example.com':
    port    => $apache_port,
    docroot => $apache_docroot,
  }

}
