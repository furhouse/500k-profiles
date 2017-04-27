class profiles::puppetserver {

  $jvm_heap_size = hiera('profiles::puppetserver::jvm_heap_size', '2g')

  class { '::puppet':
    server                      => true,
    agent                       => true,
    server_foreman              => true,
    server_ca                   => hiera('profiles::puppetserver::server_ca', false),
    ca_server                   => hiera('profiles::puppetserver::ca_server', undef),
    server_common_modules_path  => hiera_array('profiles::puppetserver::basemodulepath', []),
    server_environments         => hiera_array('profiles::puppetserver::environments', []),
    server_jvm_min_heap_size    => $jvm_heap_size,
    server_jvm_max_heap_size    => $jvm_heap_size,
    server_reports              => hiera('profiles::puppetserver::server_reports', 'foreman'),
    server_puppetdb_host        => hiera('profiles::puppetserver::puppetdb_host', undef),
    server_storeconfigs_backend => hiera('profiles::puppetserver::storeconfigs_backend', 'puppetdb'),
    server_parser               => hiera('profiles::puppetserver::server_parser', 'current'),
    listen                      => hiera('profiles::puppetserver::listen', true),
    show_diff                   => hiera('profiles::puppetserver::show_diff', true),
  }

}
