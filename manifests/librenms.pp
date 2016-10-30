class profiles::librenms {

  # install some dependency packages (uses puppetlabs/stdlib)
  ensure_packages(['php5-mysql', 'php5-mcrypt', 'php5-gd', 'php5-snmp', 'php-pear', 'python-mysqldb', 'php-net-ipv4', 'php-net-ipv6', 'rrdtool'])

  # install librenms, config data is taken from hiera
  include ::librenms

  class { '::librenms:mysql':
    mysql_pass     => hiera('librenms_mysql_pass', undef),
  }

  apache::vhost { 'librenms':
    servername     => "nms.${::fqdn}",
    manage_docroot => '/opt/librenms/html',
    port           => '80',
    docroot        => '/opt/librenms/html',
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}:443%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost { 'librenms-ssl':
    servername     => "nms.${::fqdn}",
    manage_docroot => false,
    ip             => '*',
    port           => '443',
    docroot        => '/opt/librenms/html',
    default_vhost  => false,
    ssl            => true,
  }

}
