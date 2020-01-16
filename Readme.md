# Overview

This is a collection of scripts for bridging staff users from Voyager to Alma.

## Requirements
  * net-ldap
  * logging
  * ruby-oci8 https://www.rubydoc.info/gems/ruby-oci8/2.2.7/file/docs/install-instant-client.md and https://www.rubydoc.info/gems/ruby-oci8/2.2.7

## Flow

  1. Create a text file with a list of uins (comments allowed with #)
  1. Run `ruby get_netids.rb filename` to create \_data/staff\_added\_netids.yml
  1. Run `ruby get_circ_profiles.rb` to create \_data/staff\_added\_staff\_scopes.yml
  1. Double-check that file to make sure the scopes look right and add any needed for testing. You may want to modify circ\_profile\_name\_to\_alma\_library.map
  1. Run `ruby get_alma_xml.rb`. Thsi will populate \_current\_xml with xml files, one per user, following the convention uin.xml
  1. Run `ruby create_updated_records.rb`. This will populate _updated_xml with an xml file per person. This file will have eppn added if it was missing and any roles that were specified by combining the default roles with the scopes found in staff\_added\_scopes.yml.
  1. Run `ruby update_users.rb | tee -a user_upload_yyyy_mm_dd_run_x.txt`. This does a "put" http request to post the users` xml doc up to Alma. There's not really logging set up yet, so you'll want to capture the output of the command
  
## circ\_profile\_name\_to\_alma\_library.map

By default at the moment we:
   * query Voyager to find the circ profile names associated with a person.
   * For each profile name we...
   ** Just use everything before Level
   ** remove all spaces
   ** uppercase the levels
   
We use that to look into the mapping file. If that pattern is found, then the scopes listed are used. Otherwise we assume that there's a scope existing that is the same as the lookup kee.

This is currently used for a set of roles that we want scoped by default at the moment...
Requests Operator (51), Circulation Desk Operator (32), Circulation Desk Manager (221)


###Example 

Sally has 'Engineering Level 6', 'Rhl Level 6'.  and 'Lit Lang Level 6'

#### Engineering Level 6
"Engineering Level 6" becomes ENGINEERING

That appears in the mapping and has one code, ENGINEER. ENGINEER will be used instead of ENGINEERING when creating the XML document in the scope for the three roles.

So Sally will have three roles created for ENGINEER: Requests Operator (51) scoped to ENGINEER,  Circulation Desk Operator (32) scoped to ENGINEER, and Circulation Desk Manager (221) scoped to ENGINEER

#### Rhl Level 6

"Rhl Level 6" becomes RHL

There's four scope codes assocaited with this: 
    - RESHALLALL
    - RESHALLFLO
    - RESHALLIKE
    - RESHALLILL

And for the three "role types" given above,those will be used

So Sally will have...
Requests Operator (51) scoped to RESHALLALL,  Circulation Desk Operator (32) scoped to RESHALLALL, and Circulation Desk Manager (221) scoped to RESHALLALL

Requests Operator (51) scoped to RESHALLFLO,  Circulation Desk Operator (32) scoped to RESHALLFLO, and Circulation Desk Manager (221) scoped to RESHALLFLO

Requests Operator (51) scoped to RESHALLIKE,  Circulation Desk Operator (32) scoped to RESHALLIKE, and Circulation Desk Manager (221) scoped to RESHALLIKE

Requests Operator (51) scoped to RESHALLILL,  Circulation Desk Operator (32) scoped to RESHALLILL, and Circulation Desk Manager (221) scoped to RESHALLILL


#### Lit Lang Level 6

"Lit Lang 6" becomes LITLANG

This doesn't appear in the mapping file, so it's used as is...

Requests Operator (51) scoped to LITLANG,  Circulation Desk Operator (32) scoped to LITLANG, and Circulation Desk Manager (221) scoped to LITLANG



#### All mappings done


So in total this process will give Sally 20 roles that are scoped:

(3 roles for ENGINEER, 12 roles for RHL, and 3 roles for LITLANG)



   
   
   
   uppercase and remove spaces 'll query Voyager circ profiles and use the language before "LeveL

This file is a yml file 

  
  * pattern2library.csv - lists patterns in circ policy names that translates to certain libraries to set scope scope 


## testing output xml before uploading it...



xmllint --schema ../rest_user.xsd --noout _updated_xml/*xmlj
create_updated_records.rb
get_alma_xml.rb
get_circ_profiles.rb
get_netids.rb
role.rb
update_users.rb
ruby update_users.rb | tee -a update_results_run3.txt


## TO DO

* Pull hardcoded role scope stuff into a configuration (somehow)
* If match role_type and scope, but inactive -> just make active
* Pull out API stuff to better handle rate-limiting as well as checking for rejections due ot api limits being released
* add better logging and alerts
* make templates for configuration files
