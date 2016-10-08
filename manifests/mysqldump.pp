class profiles::mysqldump {

  file { 'dbbackup-dir':
    ensure => 'directory',
    path   => '/var/backups/mysql',
  }

  file { 'dbbackup-script':
    ensure  => 'present',
    path    => '/usr/local/bin/dbbackup',
    mode    => '0755',
    source  => "puppet:///modules/${module_name}/dbbackup",
    require => File['dbbackup-dir'],
  }

  cron { 'dbbackup':
    command => '/usr/local/bin/dbbackup > /dev/null',
    user    => root,
    hour    => 0,
    minute  => 0,
    require => File['dbbackup-script'],
  }

}
