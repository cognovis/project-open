# customer_id. Party ID of the customer for which the complaint was made.
# supplier_id. Party ID of the supplier who caused the complaint. 
#              If supplier_id equals "-100" then a null value is inserted
# project_id.  Alternative for the customer_id, if you know the project_id

# 2006/11/03 cognovis/nfl: project_id was never used - it seems to be just the remark above :-)
#                          now, if a project_id was given, the title gets the value of the project title (content::item::get_title)
#                          note: the project_id is an item_id


if { ![info exist return_url] } {
    set return_url [get_referrer]
}

if { ![info exist mode] } {
    set mode "edit"
}

if { ![exists_and_not_null complaint_id] } {
    if { [info exist complaint_id] } {
	unset complaint_id
    }
    set complaint_rev_id ""
} else {
    set complaint_rev_id $complaint_id
}

set title_default_value ""
if { [info exist project_id] } {
    set title_default_value [lang::util::localize [content::item::get_title -item_id $project_id]]
}

ad_form -mode $mode -name complaint_form -form {
    complaint_id:key
    {title:text(text)
	{label "[_ intranet-contacts.Title_1]"}
        {help_text "[_ intranet-contacts.complaint_title_help]"}
	{value $title_default_value}
    }
    {return_url:text(hidden)
	{value $return_url}
    }
}

set package_url [ad_conn package_url]
set customer_name [contact::name -party_id $customer_id]
ad_form -extend -name complaint_form -form {
    {customer_id:text(hidden)
	{value $customer_id}
    }
    {customer:text(inform),optional
	{label "[_ intranet-contacts.Customer]"}
	{value "<a href=\"${package_url}${customer_id}\">$customer_name</a>"}
    }
}

if { [exists_and_not_null customer_id]} {
    # We get all the employees of this customer_id
    set emp_options [list]
    lappend emp_options [list "- - - - - -" ""]
    set employee_list [contact::util::get_employees -organization_id $customer_id]
    foreach emp_id $employee_list {
	set emp_name [contact::name -party_id $emp_id]
	append emp_name " ([contact::email -party_id $emp_id])"
	lappend emp_options [list $emp_name $emp_id]
    }
    ad_form -extend -name complaint_form -form {
	{employee_id:text(select),optional
	    {label "[_ intranet-contacts.Employee]:"}
	    {options $emp_options}
	    {value ""}
	}
    }
} else {
    ad_form -extend -name complaint_form -form {
	{employee_id:text(hidden)
	    {label "[_ intranet-contacts.Employee]:"}
	    {value ""}
	}
	{employee_inform:text(inform)
	    {label "[_ intranet-contacts.Employee]:"}
	    {value "[_ intranet-contacts.Customer_has_no_employees]"}
	}
    }
}

if { ![exists_and_not_null supplier_id]} {
    set user_options [list]
    db_foreach get_users { } {
	lappend user_options [list $fullname $user_id]
    }
    db_foreach get_groups { } {
	lappend user_options [list $group_name $group_id]
    }
    ad_form -extend -name complaint_form -form {
	{supplier_id:text(select),optional
	    {label "[_ intranet-contacts.Supplier]"}
	    {options $user_options}
	}
    }
} else {
    set supplier_name ""
    if { ![string equal $supplier_id "-100"] } {
	set supplier_name [contact::name -party_id $supplier_id]
    } else {
	set supplier_id ""
    }
    ad_form -extend -name complaint_form -form {
	{supplier_id:text(hidden)
	    {value $supplier_id}
	}
	{supplier:text(inform),optional
	    {label "[_ intranet-contacts.Supplier]"}
	    {value "$supplier_name"}
	}
    }
}

ad_form -extend -name complaint_form -form {
    {turnover:text(text),optional
	{label "[_ intranet-contacts.Turnover]"}
	{html {size 10}}
        {help_text "[_ intranet-contacts.complaint_turnover_help]"}
    }
    {percent:text(text),optional
	{label "[_ intranet-contacts.Percent]"}
	{html {size 2}}
	{after_html "%"}
        {help_text "[_ intranet-contacts.complaint_percent_help]"}
    }
}

ad_form -extend -name complaint_form -form {
    {complaint_object_id:text(hidden)
	{value $complaint_object_id}
    }
    {project:text(inform)
	{label "[_ intranet-contacts.Object]"}
    }
}

ad_form -extend -name complaint_form -form {
    {paid:text(text),optional
	{label "[_ intranet-contacts.Paid]"}
	{html {size 10}}
        {help_text "[_ intranet-contacts.complaint_paid_help]"}

    }
    {refund_amount:text(text),optional
	{label "[_ intranet-contacts.Refund]:"}
	{html {size 10}}
	{help_text "[_ intranet-contacts.complaint_refund_help]"}
    }
    {state:text(select),optional
	{label "[_ intranet-contacts.Status]"}
	{options { { [_ intranet-contacts.open] open } { [_ intranet-contacts.valid] valid } { [_ intranet-contacts.invalid] invalid } }}
        {help_text "[_ intranet-contacts.complaint_status_help]"}
    }
    {description:text(textarea)
	{label "[_ intranet-contacts.Description]"}
	{html {rows 10 cols 30}}
        {help_text "[_ intranet-contacts.complaint_description_help]"}
    }
} -validate {
    {title
	{ ![contact::complaint::check_name -name $title -complaint_id $complaint_rev_id] }
	"[_ intranet-contacts.title_already_present]"
    }
} -new_data {
  
    contact::complaint::new \
	-customer_id $customer_id \
	-title $title \
	-turnover $turnover \
	-percent $percent \
	-description $description \
	-supplier_id $supplier_id \
	-paid $paid \
	-complaint_object_id $complaint_object_id \
	-state $state \
	-employee_id $employee_id \
	-refund_amount $refund_amount 
    

} -edit_data {
    
    contact::complaint::new \
	-complaint_id $complaint_id \
	-customer_id $customer_id \
	-title $title \
	-turnover $turnover \
	-percent $percent \
	-description $description \
	-supplier_id $supplier_id \
	-paid $paid \
	-complaint_object_id $complaint_object_id \
	-state $state \
	-employee_id $employee_id \
	-refund_amount $refund_amount 

} -new_request {
    if { [exists_and_not_null complaint_object_id]} {
	set project "[pm::project::name -project_item_id $complaint_object_id]"
    }
} -edit_request {

    db_1row get_revision_info { }
    if { [exists_and_not_null complaint_object_id] } {
	set project "[pm::project::name -project_item_id $complaint_object_id]"
    }

} -after_submit {
    ad_returnredirect $return_url
}

