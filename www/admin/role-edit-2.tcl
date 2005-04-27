# /packages/acs-workflow/www/admin/role-edit-2.tcl
ad_page_contract {
     Edits a role

     @author Lars Pind (lars@pinds.com)
     @creation-date Feb 27, 2001
     @cvs-id $Id$
} {
    workflow_key:notnull
    role_key:notnull
    role_name:notnull
    {return_url "workflow-roles?[expolrt_vars -url {workflow_key}]"}
    cancel:optional
} -validate {
    role_name_unique -requires { workflow_key:notnull role_name:notnull role_key:notnull } {
	set num_rows [db_string num_roles {
	    select count(*) 
	    from   wf_roles
	    where  workflow_key = :workflow_key
	    and    role_name = :role_name
            and    role_key != :role_key
	}]

        if { $num_rows > 0 } {
	    ad_complain "There is already another role with this name"
	}
    }
}

if { ![info exists cancel] || [empty_string_p $cancel] } {
    db_dml edit_role {
	update wf_roles
	   set role_name = :role_name
	 where workflow_key = :workflow_key
	   and role_key = :role_key
    }   
}

ad_returnredirect $return_url

