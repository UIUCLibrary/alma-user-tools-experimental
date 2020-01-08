# Overview

This is a collection of scripts for bridging staff users from Voyager to Alma.

## Requirements
  * net-ldap
  * logging
  * ruby-oci8 https://www.rubydoc.info/gems/ruby-oci8/2.2.7/file/docs/install-instant-client.md and https://www.rubydoc.info/gems/ruby-oci8/2.2.7

## Flow

  1. Create a text file with a list of uins (comments allowed with #)
  1. Use uins to find netids
  1. Use netids to find circ profile names
  1. Map to particular scop
  1. Get xml file from Alma for user
  1. Add in eppn if missing from identifiers (should probably do separately, or reuse code somehow)
  1. Add in missing roles
  1. Upload file

## Parts and files

  * pattern2library.csv - lists patterns in circ policy names that translates to certain libraries to set scope scope 


