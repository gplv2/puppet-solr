define solr::core(
  $solrconfig = 'solr/solrconfig.xml.erb',
  $data       = 'puppet:///modules/solr/conf/',
) {

  $solr_home = "/opt/solr/"

  #Create this core's config directory
  exec { "mkdir-p-${title}":
    path => ['/usr/bin', '/usr/sbin', '/bin'],
    command => "mkdir -p ${solr_home}/${title}",
    unless => "test -d ${solr_home}/${title}",
    require => Package['solr-jetty'],
  }

  #Copy its config over
  file { "core-${title}-conf":
    ensure  => directory,
    recurse => true,
    path    => "${solr_home}/${title}/conf",
    source  => $data,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec["mkdir-p-${title}"],
  }

  #Copy the respective solrconfig.xml file
  file { "solrconfig-${title}":
    ensure  => file,
    path    => "${solr_home}/${title}/conf/solrconfig.xml",
    content => template($solrconfig),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["core-${title}-conf"],
  }

  #Finally, create the data directory where solr stores
  #its indexes with proper directory ownership/permissions.
  file { "${title}-data-dir":
    ensure  => directory,
    path    => "/var/lib/solr/${title}",
    owner   => "jetty",
    group   => "jetty",
    require => File["solrconfig-${title}"],
    before  => File['solr.xml'],
  }

}
