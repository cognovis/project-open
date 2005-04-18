ad_page_contract {
  @cvs-id $Id: group.tcl,v 1.1 2005/04/18 21:32:35 cvs Exp $
} -properties {
  users:multirow
}


set query "select 
             first_name, last_name, state
           from
             ad_template_sample_users
           order by state, last_name"


db_multirow users users_query $query
