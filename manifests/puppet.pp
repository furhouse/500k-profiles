class profiles::puppet {

  $is_puppetmaster = hiera('is_puppetmaster', false)

  if !$is_puppetmaster {

    class { '::puppet':
      agent        => true,
      server       => false,
      puppetmaster => hiera('puppetmaster', undef),
      show_diff    => true,
      listen       => true,
    }
  }

}
