# == Class: solr
#
# This module helps you create a multi-core solr install
# from scratch. I'm packaging a version of solr in the files
# directory for convenience. You can replace it with a newer
# version if you like.
#
# IMPORTANT: Works only with Ubuntu as of now.
#
# === Parameters
#
# Document parameters here.
#
# [*port*]
#   "The port in which jetty will run on."
#
# [*java_home*]
#   "Depending on Java version this will need to be updated accordingly."
#
# === Examples
#
#  class { solr: }
#
class solr (
  $cores     = [],
  $port      = "8080",
  $java_home = '$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")',
  $contrib   = 'puppet:///modules/solr/contrib/'
) {

  $jetty_home = "/usr/share/jetty"
  $solr_home = "/usr/share/solr"

  package { 'solr-jetty':
    ensure => present,
  }

  package { 'openjdk-6-jdk':
    ensure => present,
  }

  # Removes existing solr install
  exec { 'rm-web-inf':
    command => "rm -rf ${solr_home}/WEB-INF",
    path    => ["/usr/bin", "/usr/sbin", "/bin"],
    onlyif  => "test -d ${solr_home}/WEB-INF",
    require => Package['solr-jetty'],
  }

  # Removes existing solr config
  exec { 'rm-default-conf':
    command => "rm -rf ${solr_home}/conf",
    path    => ["/usr/bin", "/usr/sbin", "/bin"],
    onlyif  => "test -d ${solr_home}/conf",
    require => Exec['rm-web-inf'],
  }

  # Removes existing solr webapp in jetty
  exec { 'rm-solr-link':
    command => "rm -rf ${jetty_home}/webapps/solr",
    path    => ["/usr/bin", "/usr/sbin", "/bin"],
    onlyif  => "test -L ${jetty_home}/webapps/solr",
    require => Exec['rm-default-conf'],
  }

  # Replaces with our newer version. You can download the
  # latest version and add it if you need latest features.
  file { 'solr.war':
    ensure  => file,
    path    => "${jetty_home}/webapps/solr.war",
    source  => "puppet:///modules/solr/solr.war",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['rm-solr-link'],
  }

  # Add a new solr context to jetty
  file { 'jetty-context.xml':
    ensure  => file,
    path    => "${jetty_home}/contexts/solr.xml",
    source  => "puppet:///modules/solr/jetty-context.xml",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['solr.war'],
  }

  # Copy the jetty config file
  file { 'jetty-default':
    ensure  => file,
    path    => "/etc/default/jetty",
    content => template('solr/jetty-default.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['jetty-context.xml']
  }

  # Copy the solr config file
  file { 'solr.xml':
    ensure  => file,
    path    => "${solr_home}/solr.xml",
    content => template('solr/solr.xml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['jetty-default'],
  }

  # Copy the extraction library.
  file { 'contrib':
    ensure  => directory,
    recurse => true,
    path    => "${solr_home}/contrib",
    source  => $contrib,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['solr-jetty'],
  }

  # Restart after copying new config
  service { 'jetty':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['solr.xml'],
  }

}
