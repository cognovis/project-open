ad_page_contract {
  @cvs-id $Id: grid.tcl,v 1.2 2010/10/19 20:13:12 po34demo Exp $
} -properties {
  users:multirow
}


set query "select 
             first_name, last_name
           from
             ad_template_sample_users"


db_multirow users users_query $query



















