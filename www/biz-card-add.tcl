ad_page_contract {

    Selection page to enter a new contact base data.

    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2008-03-28
    @cvs-id $Id$
} {
    {first_names "" }
    {last_name "" }
    {email "" }
    {company_name "" }
    {contact_type "" }
    {form_mode "edit" }
    {return_url ""}
    {orderby "rank,desc" }
    {button_search "" }
    {button_new_user_company "" }
}

# --------------------------------------------------
# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

set title "[_ intranet-contacts.Add_a_Biz_Card]"
set context [list $title]
set current_user_id [ad_maybe_redirect_for_registration]


# --------------------------------------------------
# Environment information for the rest of the page

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]
set required_field "<font color=red size=+1><B>*</B></font>"

set search_results_p 0


# ------------------------------------------------------------------
# Normalize input fields
# ------------------------------------------------------------------
    
set found_user_id [db_string found_uid "select party_id from parties where lower(email) = :email" -default ""]
if {"" == $found_user_id} {
    set found_user_ids [db_list found_uids "select person_id from persons where lower(first_names) = :first_names and lower(last_name) = :last_name"]
    set found_user_id [lindex $found_user_ids 0]
}

if {"" != $found_user_id} {
    db_1row found_user_info "
	select	im_name_from_user_id(u.user_id) as found_user_name,
		email as found_user_email
	from	cc_users u
	where	u.user_id = :found_user_id
    "
}

set found_company_id [db_string found_uid "select company_id from im_companies where lower(company_name) = :company_name" -default ""]
if {"" == $found_company_id} {
    set found_company_id [db_string found_uid "select company_id from im_companies where lower(company_path) = :company_name" -default ""]
}



# ------------------------------------------------------------------
# Action
# ------------------------------------------------------------------

# Determine profiles (groups) per contact type
switch $contact_type {
    customer { set profile [list [im_customer_group_id]]  }
    provider { set profile [list [im_freelance_group_id]] }
    employee { set profile [list [im_employee_group_id]] }
    default { set profile [list] }
}

# Add a new user action - 
# Redirect to user new page and set profile according to type of contact
if {"" != $button_new_user_company} {
    ad_returnredirect [export_vars -base "/intranet-contacts/biz-card-add-3.tcl" {first_names last_name email company_name profile}]
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set contact_options [list \
			 [list [lang::message::lookup "" intranet-core.Customer "Customer"] customer] \
			 [list [lang::message::lookup "" intranet-core.Provider "Provider"] provider] \
			 [list [lang::message::lookup "" intranet-core.Undefined "Undefined"] undefined] \
			]

set form_id "contact"

set actions [list]
lappend actions [list [lang::message::lookup {} intranet-timesheet2.Edit Edit] edit]
lappend actions [list [lang::message::lookup {} intranet-timesheet2.Delete Delete] delete]

# ad_return_complaint 1 [template::form get_action $form_id]

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action "biz-card-add" \
    -actions $actions \
    -has_edit 1 \
    -method GET \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {contact_type:text(select),optional {label "[lang::message::lookup {} intranet-core.Contact_Type {Contact Type}]"} {options $contact_options}}
	{first_names:text(text),optional {label "[_ intranet-core.First_names]"} {html {size 30}}}
	{last_name:text(text),optional {label "[_ intranet-core.Last_name]"} {html {size 30}}}
    	{email:text(text),optional {label "[_ intranet-core.Email]"} {html {size 30}} {help_text ""}}
	{company_name:text(text),optional {label "[lang::message::lookup {} intranet-core.Company_name {Company Name}]"} {html {size 30}}}
	{button_search:text(submit) {label "[lang::message::lookup {} intranet-core.Search {Search}]"}}
    }

# Show action buttons only if we have searched before
if {"" != $button_search} {

    ad_form -extend -name $form_id -form {
	{button_new_user_company:text(submit) {label "[lang::message::lookup {} intranet-core.New_User_Company {New User + Company}]"}}
    }
}



ad_form -extend -name $form_id -new_request {

    # Nada. No actin necessary (so far?)

} -on_submit {

    # ------------------------------------------------------------------
    # Build the list
    # ------------------------------------------------------------------
    
    lappend action_list "Add page" "[export_vars -base "layout-page" { object_type }]" "Add item to this order"
    
    list::create \
	-name contact_list \
	-multirow contact_multirow \
	-key user_id \
	-actions $action_list \
	-no_data "[lang::message::lookup {} intranet-core.No_contacts_found {No contacts found}]" \
	-elements {
	    rank { 
		label "[lang::message::lookup {} intranet-core.Rank {Rank}]" 
	    }
	    first_names { 
		label "[lang::message::lookup {} intranet-core.First_names {First Names}]" 
		link_url_col user_url
	    }
	    last_name { 
		label "[lang::message::lookup {} intranet-core.Last_name {Last Name}]" 
		link_url_col user_url
	    }
	    email { 
		label "[lang::message::lookup {} intranet-core.Email {Email}]" 
		link_url_col user_url
	    }
	    contact_type { 
		label "Type" 
		display_template {
		    <if @contact_multirow.contact_type@ eq "relative">
		    <a href="@contact_multirow.edit_url@" class="button">@contact_multirow.contact_type@</a>
		    </if>
		    <else>
		    @contact_multirow.contact_type@
		    </else>
		}
	    }
	    action {
		label ""
		display_template {
		    @contact_multirow.action_html;noquote@
		}
	    }
	} \
	-orderby {
	    rank {orderby rank}
	    first_names {orderby first_names}
	    contact_type {orderby contact_type}
	}



    set first_names [string tolower [string trim $first_names]]
    set last_name [string tolower [string trim $last_name]]
    set email [string tolower [string trim $email]]
    set company_name [string tolower [string trim $company_name]]

    set q_list [list]
    set or_query [list]
    if {"" != $first_names} { 
	lappend q_list $first_names 
	lappend or_query "lower(u.first_names) like '%$first_names%'"
    }
    if {"" != $last_name} { 
	lappend q_list $last_name 
	lappend or_query "lower(u.last_name) like '%$last_name%'"
    }
    if {"" != $email} { 
	lappend q_list $email 
	lappend or_query "lower(u.email) like '%$email%'"
    }
    if {"" != $company_name} { 
	lappend q_list $company_name 
    }
    
    set q [join $q_list " | "]
    set or_clause [join $or_query "\n\t\t\tOR " ]
    if {"" == $or_clause} { set or_clause "1=0" }
    
    
    set inner_sql "
			select
				u.user_id,
				1 as rank
			from
				cc_users u
			where
				$or_clause
		    UNION
			select
				so.object_id as user_id,
		                (rank(so.fti, :q::tsquery) * sot.rel_weight)::numeric(12,2) as rank
			from
				im_search_objects so,
				im_search_object_types sot
			where
				so.object_type_id = sot.object_type_id and
				so.fti @@ to_tsquery('default',:q)
    "

    # Sum up the ranks of the two searches
    set middle_sql "
	select	sum(u.rank) as rank,
		u.user_id
	from
		($inner_sql) u
	group by
	      u.user_id
    "

    set contact_sql "
	select
		uu.rank,
		u.*,
		cust.group_id as cust_group_id,
		prov.group_id as prov_group_id,
		empl.group_id as empl_group_id
	from
		($middle_sql) uu,
		cc_users u
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_customer_group_id]) cust ON cust.member_id = u.user_id
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_freelance_group_id]) prov ON prov.member_id = u.user_id
		LEFT OUTER JOIN (select * from group_distinct_member_map where group_id = [im_employee_group_id]) empl ON empl.member_id = u.user_id
	where
		u.user_id = uu.user_id
	[template::list::orderby_clause -name contact_list -orderby]
    "

    db_multirow -extend {user_url delete_url contact_type action_html} contact_multirow get_similar_contacts $contact_sql {

	set user_url [export_vars -base "/intranet/users/new" { user_id return_url }]
	set delete_url [export_vars -base "contact-del" { object_type page_url }]
	set contact_type ""
	if {"" != $empl_group_id} { append contact_type [lang::message::lookup "" intranet-core.Employee "Employee"] }
	if {"" != $cust_group_id} { append contact_type [lang::message::lookup "" intranet-core.Customer "Customer"] }
	if {"" != $prov_group_id} { append contact_type [lang::message::lookup "" intranet-core.Provider "Provider"] }
	
	set also_add_users [list $user_id [im_biz_object_role_full_member]]
	set action_text [lang::message::lookup "" intranet-core.Create_new_company_for_this_user "Create new company for this user"]
	set action_url [export_vars -base "/intranet/companies/new" {also_add_users}]
	set action_html "<a href='$action_url' class=button>$action_text</a>"
    }

    set search_results_p 1

}