# /packages/acs-workflow/www/admin/role-add-2.tcl
ad_page_contract {
     Adds a role

     @author Jesse Koontz  [jkoontz@arsdigita.com]
     @creation-date Thu Jan 25 09:32:52 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    role_name:notnull
    {return_url "workflow-roles?[expolrt_vars -url {workflow_key}]"}
} -validate {
    role_name_unique -requires { workflow_key:notnull role_name:notnull } {
	set num_rows [db_string num_roles {
	    select count(*) 
	    from   wf_roles
	    where  workflow_key = :workflow_key
	    and    role_name = :role_name
	}]

        if { $num_rows > 0 } {
	    ad_complain "There is already a role with this name"
	}
    }
}

wf_add_role \
	-workflow_key $workflow_key \
	-role_name $role_name

ad_returnredirect $return_url

