class profiles::postfixadmin {

  include '::staging'

  staging::deploy { 'postfixadmin-2.93.tar.gz':
    source => "puppet:///modules/${module_name}/postfixadmin-2.93.tar.gz",
    target => '/usr/share',
    user   => 'root',
    group  => 'root',
  }

  profiles::postfixadmincfg { "postfixadmin-config-${fqdn}": }

}
