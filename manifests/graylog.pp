class profiles::graylog {

  apt::ppa { 'ppa:openjdk-r/ppa':
    package_manage => true,
  }

  class { '::java':
    distribution => 'jre',
    package      => 'openjdk-8-jre',
    version      => 'present',
  }

  Apt::Ppa['ppa:openjdk-r/ppa'] -> Class['apt::update'] -> Class['::java']

  class { '::mongodb::globals':
    manage_package_repo => true,
    require             => Class['apt::update'],
  }

  class { '::mongodb::server':
    bind_ip     => ['127.0.0.1'],
    pidfilepath => '/var/lib/mongodb/mongod.pid',
    require     => Class['::mongodb::globals']
  }

  class { '::elasticsearch':
    version      => '2.3.2',
    repo_version => '2.x',
    manage_repo  => true,
  }

  elasticsearch::instance { 'graylog':
    config  => {
      'cluster.name' => 'graylog',
      'path.repo'    => '/var/lib/elasticsearch-graylog/snapshot',
    },
    require => Class['::elasticsearch']
  }

  elasticsearch::plugin {'lmenezes/elasticsearch-kopf':
    instances => 'graylog',
    require   => Class['::elasticsearch']
  }

  class { '::graylog::repository':
    version => '2.1',
    require => [ Class['::elasticsearch'], Class['::mongodb::server'] ],
  }

  class { '::graylog::server':
    package_version => '2.1.2-1',
    config          => {
      'password_secret'          => hiera('graylog::pass', undef),
      'root_password_sha2'       => hiera('graylog::sha2', undef),
      'root_timezone'            => 'Europe/Amsterdam',
      'versionchecks'            => false,
      'usage_statistics_enabled' => false,
      'rest_listen_uri'          => 'http://0.0.0.0:12900/',
      'web_listen_uri'           => 'http://0.0.0.0:9000/',
    },
    require         => Class['::graylog::repository']
  }
}
