# manage_dependencies is set to false because I've included the installation 
# of git into common.yaml

define profiles::mod_gelf (
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

  }

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
