# /packages/intranet-mail-import/www/get-mail-list.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.

ad_page_contract {

    return json of object atributes for users & projects 	
		
    @author klaus.hofeditz@project-open.com
    @creation-date May 2012
} {
    { view_mode "json" }
    { callback "" }
    { query ""}
}

# #####################
# Defaults and Security 
# #####################

set user_id [ad_maybe_redirect_for_registration]
set query "%${query}%"

# #####################
# Find records
# #####################

set sql "
	select 
		project_id as object_id,
		'im_project' as object_type, 
		project_name as object_name, 
		project_nr as object_nr,
 		'0' as order_by 
	from 
		im_projects 
	where 
		project_name like :query 
		or project_nr like :query 
	
	UNION 
	
	select 
		object_id as object_id,
		'im_user' as object_type,
		im_name_from_user_id(object_id) as object_name,
		'0' as object_nr,
		'1' as order_by
 
	from 
		cc_users
	where 
		first_names like :query or
		last_name like :query 
	order by
		order_by
	"

set ctr 0 
set record_list_tmp [list]
                db_foreach mail_list $sql {
		    set json_record_list ""
                    append json_record_list "{\"object_id\":\"$object_id\",\n"
                    append json_record_list "\"object_type\":\"$object_type\",\n"
                    append json_record_list "\"object_name\":\"$object_name\",\n"
                    append json_record_list "\"object_nr\":\"$object_nr\",\n"
		    append json_record_list "}\n"
		    lappend record_list_tmp $json_record_list
		    incr ctr
                }

set record_list [join $record_list_tmp ", "]
