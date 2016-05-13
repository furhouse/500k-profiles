class profiles::graylog {

  class { '::mongodb::globals':
    manage_package_repo => true,
  }->
  class { '::mongodb::server':
    bind_ip => ['127.0.0.1'],
  }

  class { '::elasticsearch':
    version      => '2.3.2',
    repo_version => '2.x',
    manage_repo  => true,
  }->
  elasticsearch::instance { 'graylog':
    config => {
      'cluster.name' => 'graylog',
      'network.host' => '127.0.0.1',
    },
  }

  class { '::graylog::repository':
    version => '2.0',
  }->
  class { '::graylog::server':
    package_version => '2.0.0-5',
    config          => {
      'password_secret'    => hiera('graylog::pass', undef),
      'root_password_sha2' => hiera('graylog::sha2', undef),
    },
  }
}
