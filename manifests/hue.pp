class profiles::hue {

  file { '01.png':
    ensure => 'present',
    source => "puppet:///modules/${module_name}/01.png",
    path   => '/var/www/01.png',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0640',
  }

  file { 'index.html':
    ensure  => 'present',
    source  => "puppet:///modules/${module_name}/index.html",
    path    => '/var/www/index.html',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0640',
    require => File['01.png'],
  }

  file { 'original-html-dir':
    ensure  => 'absent',
    path    => '/var/www/html',
    recurse => true,
    purge   => true,
    force   => true,
  }

  apache::vhost { 'hue':
    servername     => "${::fqdn}",
    serveraliases  => ["irc.${::fqdn}"],
    manage_docroot => false,
    port           => '80',
    docroot        => '/var/www',
    default_vhost  => true,
    rewrites       => [
      {
        comment      => 'redirect to https',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost { 'hue-ssl':
    servername     => "${::fqdn}",
    manage_docroot => false,
    ip             => '*',
    port           => '443',
    docroot        => '/var/www',
    default_vhost  => true,
    ssl            => true,
    ssl_cert       => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
    ssl_key        => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
    ssl_chain      => "/etc/letsencrypt/live/${::fqdn}/chain.pem",
    headers        => 'always set Strict-Transport-Security "max-age=15552001; includeSubDomains; preload"',
  }

}
