# Solr Module

This is a puppet module for setting up a multi-core solr instance. 

## Quick Start

Put this in your solr.pp file and run sudo puppet apply:

    class { solr: }
    solr::core { 'my_core': }

**NOTE**: Currently only Ubuntu is supported, contributions for other platforms are most welcome. 
The code is well commented, and should give you a clear idea about how this module 
configures solr. Please read those for more information.

## TODO

 * Support other platforms
