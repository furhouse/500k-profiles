class profiles::motd {

  $news = hiera('profiles::motd::news')

  create_resources('::motd::news', $news)

}
