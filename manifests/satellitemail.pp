class profiles::satellitemail {

  $satellite = hiera('satellite_mail', false)

  if $satellite {

    class { '::postfix':
      master_smtp => 'smtp inet n - n - - smtpd',
      myorigin    => hiera('satellite_origin', undef),
    }

    postfix::config {
      'relayhost':                      value => hiera('satellite_relay', undef);
      'smtp_sasl_auth_enable':          value => 'yes';
      'smtp_sasl_password_maps':        value => 'hash:/etc/postfix/smtp_auth';
      'smtp_sasl_security_options':     value => 'noanonymous';
      'smtp_sasl_tls_security_options': value => 'noanonymous';
    }

    postfix::hash { '/etc/postfix/smtp_auth':
      ensure  => 'present',
      content => hiera('satellite_serv_creds', undef),
    }

  }
  else {
    notify { 'Please set the hiera key satellite_mail to true to enable the postfix satellite config.': }
  }

}
