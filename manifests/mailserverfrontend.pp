class profiles::mailserverfrontend {

  Exec {
    path => '/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  $packages = [ 'php5-mysql', 'php5-imap', 'postfix-mysql', 'dovecot-lmtpd' ]

  package { $packages:
    ensure => installed,
  }

  exec { 'enable-php5-imap':
    command => 'php5enmod imap',
    require =>  Package['php5-imap'],
    unless  => 'php -m | grep imap',
  }

  class { 'roundcube':
    imap_host   => 'ssl://localhost',
    imap_port   => 993,
    db_type     => 'mysql',
    db_name     => hiera('rcdbname', 'undef'),
    db_host     => hiera('rcdbhost', 'undef'),
    db_username => hiera('rcdbuser', 'undef'),
    db_password => hiera('rcdbpass', 'undef'),
    plugins => [
      'filesystem_attachments',
      'zipdownload',
    ],
  } ->

  apache::vhost { 'postfixadmin':
    servername     => "pfa.${::fqdn}",
    serveraliases  => ["irc.${::fqdn}"],
    manage_docroot => false,
    port           => '80',
    docroot        => '/usr/share/postfixadmin-2.93',
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}:443%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost { 'postfixadmin-ssl':
    servername      => "pfa.${::fqdn}",
    manage_docroot  => false,
    ip              => '*',
    port            => '443',
    docroot         => '/usr/share/postfixadmin-2.93',
    default_vhost   => true,
    ssl             => true,
    ssl_cert        => "/etc/letsencrypt/live/pfa.${::fqdn}/fullchain.pem",
    ssl_key         => "/etc/letsencrypt/live/pfa.${::fqdn}/privkey.pem",
    ssl_chain       => "/etc/letsencrypt/live/pfa.${::fqdn}/chain.pem",
    error_log_file  => 'postfixadmin_error.log',
    access_log_file => 'access.log',
    headers         => 'always set Strict-Transport-Security "max-age=10886400; includeSubDomains; preload"',
  }

  apache::vhost { 'roundcube':
    servername     => "mail.${::fqdn}",
    manage_docroot => false,
    port           => '80',
    docroot        => '/opt/roundcubemail-1.1.5',
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}:443%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost { 'roundcube-ssl':
    servername      => "mail.${::fqdn}",
    manage_docroot  => false,
    ip              => '*',
    port            => '443',
    docroot         => '/opt/roundcubemail-1.1.5',
    default_vhost   => false,
    ssl             => true,
    ssl_cert        => "/etc/letsencrypt/live/mail.${::fqdn}/fullchain.pem",
    ssl_key         => "/etc/letsencrypt/live/mail.${::fqdn}/privkey.pem",
    ssl_chain       => "/etc/letsencrypt/live/mail.${::fqdn}/chain.pem",
    error_log_file  => 'roundcube_error.log',
    access_log_file => 'access.log',
    headers         => 'always set Strict-Transport-Security "max-age=10886400; includeSubDomains; preload"',
  }

  roundcube::plugin { 'cor/keyboard_shortcuts':
    ensure => '2.4.1',
  }

  roundcube::plugin { 'johndoh/contextmenu':
    ensure => '2.1.2',
  }

  roundcube::plugin { 'kolab/calendar':
    ensure => '3.2.9.1',
  }

}
