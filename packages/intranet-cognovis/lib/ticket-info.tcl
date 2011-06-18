ad_page_contract {
    Displays Ticket Info Cognovis Component

    @author Iuri Sampaio (iuri.sampaio@iurix.com)
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-06-06
}


# ---------------------------------------------------------------------
# Get Everything about the project
# ---------------------------------------------------------------------

set extra_selects [list "0 as zero"]

db_foreach column_list_sql {
    select    w.deref_plpgsql_function,
              aa.attribute_name,
              aa.table_name
    from      im_dynfield_widgets w,
              im_dynfield_attributes a,
              acs_attributes aa
    where     a.widget_name = w.widget_name and
              a.acs_attribute_id = aa.attribute_id and
              aa.object_type = 'im_ticket'
}  {
    lappend extra_selects "${deref_plpgsql_function}(${table_name}.$attribute_name) as ${attribute_name}_deref"
}

set extra_select [join $extra_selects ",\n\t"]

if {[exists_and_not_null extra_select]} {
    set extra_where  "AND im_tickets.ticket_id = im_projects.project_id"
}

ns_log Notice "TICKET ID $ticket_id"


if { ![db_0or1row project_info_query "
    SELECT
                im_projects.*,
                im_companies.*,
                to_char(im_projects.end_date, 'HH24:MI') as end_date_time,
                to_char(im_projects.start_date, 'YYYY-MM-DD') as start_date_formatted,
                to_char(im_projects.end_date, 'YYYY-MM-DD') as end_date_formatted,
                to_char(im_projects.percent_completed, '999990.9%') as percent_completed_formatted,
                im_companies.primary_contact_id as company_contact_id,
                im_name_from_user_id(im_companies.primary_contact_id) as company_contact,
                im_email_from_user_id(im_companies.primary_contact_id) as company_contact_email,
                im_name_from_user_id(im_projects.project_lead_id) as project_lead,
                im_name_from_user_id(im_projects.supervisor_id) as supervisor,
                im_name_from_user_id(im_companies.manager_id) as manager,
                $extra_select
    FROM
                im_projects,
                im_companies
    WHERE       im_projects.project_id=:ticket_id
    AND         im_projects.company_id = im_companies.company_id
    $extra_where
"]} {
	ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
	return
}



set user_id [ad_conn user_id] 
set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]


# ---------------------------------------------------------------------
# Add DynField Columns to the display
# ---------------------------------------------------------------------

set ticket_type_id [db_string ptype "select ticket_type_id from im_tickets where ticket_id = :ticket_id" -default 0]

db_multirow -extend {attrib_var value} ticket_info dynfield_attribs_sql {
      select
      		aa.pretty_name,
      		aa.attribute_name
      from
      		acs_attributes aa,
                im_dynfield_type_attribute_map tam,
      		im_dynfield_attributes a
      		LEFT OUTER JOIN (
      			select *
      			from im_dynfield_layout
      			where page_url = 'default'
      		) la ON (a.attribute_id = la.attribute_id)
      where
                a.acs_attribute_id = aa.attribute_id and
                tam.attribute_id = a.attribute_id and
                tam.object_type_id = :ticket_type_id
      order by  la.pos_y
    
} {
    
    set var ${attribute_name}_deref
    set value [expr $$var]
    if {"" != [string trim $value]} {
	set attrib_var [lang::message::lookup "" intranet-core.$attribute_name $pretty_name]
    }
    
    ns_log Notice "$attribute_name | $value"
   
}


# get the current users permissions for this project
im_project_permissions $user_id $project_id view read write admin

