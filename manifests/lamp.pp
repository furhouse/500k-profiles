# manage_dependencies is set to false because I've included the installation 
# of git into common.yaml

class profiles::lamp {

  $enable_letsencrypt = hiera('enable_letsencrypt', true)
  $letsencrypt_staging = hiera('le_staging', false)

  if $enable_letsencrypt {

    package { 'python':
      ensure => installed,
    }

    class { '::letsencrypt':
      email               => hiera('le_email', "admin@${::fqdn}"),
      manage_dependencies => false,
      require             => Package['python'],
    }

    if $letsencrypt_staging {
      letsencrypt::certonly { "${::fqdn}":
        domains         => hiera_array('le_domains', []),
        additional_args => hiera_array('le_args', []),
        require         => Class['::letsencrypt'],
      }
    }
    else {
      letsencrypt::certonly { "${::fqdn}":
        domains              => hiera_array('le_domains', []),
        require              => Class['::letsencrypt'],
        cron_success_command => 'service apache2 reload',
      }
    }

  }

  class { '::apache':
    default_vhost => false,
    mpm_module    => 'prefork',
    require       => Letsencrypt::Certonly["${::fqdn}"],
  }

  class { '::apache::mod::php': }
  class { '::apache::mod::rewrite': }
  class { '::apache::mod::ssl': }

  apache::mod { 'log_gelf':
    package => 'libapache2-mod-gelf',
    require => Package['libapache2-mod-gelf'],
  }

  define modgelf_conf (
    $gelf_url      = hiera('gelf_url', undef),
    $gelf_source   = hiera('gelf_source', undef),
    $gelf_facility = hiera('gelf_facility', undef),
    $gelf_tag      = hiera('gelf_tag', undef),
    $gelf_cookie   = hiera('gelf_cookie', undef),
    $gelf_fields   = hiera('gelf_fields', undef),
  ) {
    file { 'log_gelf.conf':
      ensure  => file,
      path    => "${::apache::mod_dir}/log_gelf.conf",
      mode    => $::apache::file_mode,
      content => template('profiles/log_gelf.conf.erb'),
      require => Exec["mkdir ${::apache::mod_dir}"],
      before  => File[$::apache::mod_dir],
      notify  => Class['apache::service'],
    }

    file{ 'log_gelf.conf symlink':
        ensure  => link,
        path    => "${::apache::mod_enable_dir}/log_gelf.conf",
        target  => "${::apache::mod_dir}/log_gelf.conf",
        owner   => 'root',
        group   => $::apache::params::root_group,
        mode    => $::apache::file_mode,
        require => [
          File['log_gelf.conf'],
          Exec["mkdir ${::apache::mod_enable_dir}"],
        ],
        before  => File["${::apache::mod_enable_dir}"],
        notify  => Class['apache::service'],
      }
  }

  modgelf_conf { 'log_gelf': }

  file { 'libapache2-mod-gelf_0.2.0-1_amd64.ubuntu.deb':
    path   => '/var/cache/apt/archives/libapache2-mod-gelf_0.2.0-1_amd64.ubuntu.deb',
    source => "puppet:///modules/${module_name}/libapache2-mod-gelf_0.2.0-1_amd64.ubuntu.deb",
  }

  package { 'libapache2-mod-gelf':
    provider => dpkg,
    ensure   => latest,
    source   => '/var/cache/apt/archives/libapache2-mod-gelf_0.2.0-1_amd64.ubuntu.deb',
    require  => File['libapache2-mod-gelf_0.2.0-1_amd64.ubuntu.deb'],
  }

  class { '::mysql::server':
    root_password           => hiera('sqlrootpass', 'undef'),
    remove_default_accounts => true,
    package_name            => 'mysql-server-5.6',
    override_options        => {
      'mysqld' => {
        'table_definition_cache' => '50',
      },
    }
  }

  $sqldatabases = hiera_hash('sqldatabases', {})
  $sqlusers = hiera_hash('sqlusers', {})
  $sqlgrants = hiera_hash('sqlgrants', {})

  create_resources('mysql_database', $sqldatabases)
  create_resources('mysql_user', $sqlusers)
  create_resources('mysql_grant', $sqlgrants)

  $vhosts = hiera_hash('lamp_vhosts', {})

  create_resources('apache::vhost', $vhosts)

}
