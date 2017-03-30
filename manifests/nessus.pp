class profiles::nessus {

  class { '::nessus':
    package_name    => 'nessus',
    activation_code => hiera('profiles::nessus::activation_code', undef),
  }

}
