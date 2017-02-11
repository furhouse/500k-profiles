class profiles::mailserverbackend {

  class { '::postfix':
    master_smtp       => 'smtp inet n - n - - smtpd',
    master_submission => 'submission inet n - - - - smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_sasl_path=private/auth
  -o smtpd_sasl_security_options=noanonymous
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_login_maps=mysql:/etc/postfix/mysql_virtual_alias_maps.cf
  -o smtpd_sender_restrictions=reject_sender_login_mismatch
  -o smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject',
    use_dovecot_lda   => true,
    use_amavisd       => true,
  }

  $vid = hiera('virtual_uid', '5000')
  $pub_ipv4 = $ec2_metadata['public-ipv4'] 

  postfix::config {
    'smtp_tls_mandatory_ciphers':       value => 'high';
    'smtp_tls_security_level':          value => 'may';
    'smtp_tls_CAfile':                  value => '/etc/ssl/certs/ca-certificates.crt';
    'smtp_tls_session_cache_database':  value => 'btree:${data_directory}/smtp_tls_session_cache';
    'smtpd_tls_session_cache_database': value => 'btree:${data_directory}/smtpd_tls_session_cache';
    'smtpd_tls_security_level':         value => 'may';
    'smtpd_tls_CAfile':                 value => '/etc/ssl/certs/ca-certificates.crt';
    'smtpd_tls_auth_only':              value => 'yes';
    'smtpd_tls_ciphers':                value => 'high';
    'smtpd_tls_loglevel':               value => '1';
    'smtpd_tls_ask_ccert':              value => 'yes';
    'smtpd_sasl_exceptions_networks':   value => '$mynetworks';
    'smtpd_recipient_restrictions':     value => 'permit_mynetworks,reject_non_fqdn_recipient,permit_sasl_authenticated,reject_unauth_destination';
    'smtpd_sender_restrictions':        value => 'permit_mynetworks,reject_unknown_sender_domain';
    'smtpd_helo_restrictions':          value => 'reject_invalid_helo_hostname';
    'smtpd_data_restrictions':          value => 'reject_unauth_pipelining,reject_multi_recipient_bounce,permit';
    'smtpd_tls_protocols':              value => '!SSLv2, !SSLv3';
    'smtpd_tls_cert_file':              value => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem";
    'smtpd_tls_key_file':               value => "/etc/letsencrypt/live/${::fqdn}/privkey.pem";
    'smtpd_milters':                    value => 'inet:127.0.0.1:8891';
    'smtpd_sasl_type':                  value => 'dovecot';
    'smtpd_sasl_path':                  value => 'private/auth';
    'smtpd_sasl_auth_enable':           value => 'yes';
    'disable_vrfy_command':             value => 'yes';
    'smtpd_helo_required':              value => 'yes';
    'myhostname':                       value => "${::fqdn}";
    'inet_protocols':                   value => 'ipv4';
    'relay_domains':                    value => '*';
    'mydestination':                    value => 'localhost';
    'mynetworks':                       value => "127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $pub_ipv4/32";
    'non_smtpd_milters':                value => 'inet:127.0.0.1:8891';
    'virtual_mailbox_base':             value => '/srv/vmail';
    'virtual_mailbox_maps':             value => 'mysql:/etc/postfix/mysql_virtual_mailbox_maps.cf';
    'virtual_alias_maps':               value => 'mysql:/etc/postfix/mysql_virtual_alias_maps.cf';
    'virtual_mailbox_domains':          value => 'mysql:/etc/postfix/mysql_virtual_domains_maps.cf';
    'virtual_uid_maps':                 value => "static:$vid";
    'virtual_gid_maps':                 value => "static:$vid";
    'virtual_transport':                value => 'lmtp:unix:private/dovecot-lmtp';
    'content_filter':                   value => 'amavis:[127.0.0.1]:10024';
  }

  include amavis

  class { '::amavis::config':
    bypass_spam_checks_maps  => '( \%bypass_spam_checks, \@bypass_spam_checks_acl, \$bypass_spam_checks_re);',
    #final_virus_destiny      => 'D_REJECT; # (defaults to D_BOUNCE)',
  }

  class { '::clamav':
    manage_clamd             => true,
    manage_freshclam         => true,
    clamd_service_ensure     => 'stopped',
    freshclam_service_ensure => 'stopped',
  }

  include dovecot

  class { dovecot::ssl:
    ssl                       => 'yes',
    ssl_keyfile               => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
    ssl_certfile              => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
    ssl_protocols             => 'TLSv1.2 TLSv1.1 !SSLv2 !SSLv3',
    ssl_cipher_list           => 'ALL:!LOW:!SSLv2:!EXP:!aNULL:!SSLv3',
    ssl_prefer_server_ciphers => 'yes',
    ssl_dh_parameters_length  => '2048',
  }

  class { dovecot::mail:
    gid             => $vid,
    uid             => $vid,
    first_valid_uid => $vid,
    first_valid_gid => $vid,
    last_valid_uid  => $vid,
    last_valid_gid  => $vid,
  }

  class { dovecot::auth:
    disable_plaintext_auth => 'yes',
    auth_username_format   => '%Lu',
  }

  class { dovecot::base:
    protocols => 'imap lmtp',
  }

  include dovecot::imap

  class { dovecot::master:
    postfix          => true,
    auth_worker_user => 'vmail',
  }

  class { dovecot::mysql:
    dbname     => hiera('postfix::db_name', 'undef'),
    dbusername => hiera('postfix::db_user', 'undef'),
    dbpassword => hiera('postfix::db_passwd', 'undef'),
  }

  include '::opendkim'

  $dkimdomain  = hiera_hash('dkim::domain', {})
  $dkimtrusted = hiera_hash('dkim::trusted', {})

  if $dkimdomain {
    create_resources('opendkim::domain', $dkimdomain)
  }
  if $dkimtrusted {
    create_resources('opendkim::trusted', $dkimtrusted)
  }

}
