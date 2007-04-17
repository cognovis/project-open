# /packages/intranet-freelance/tcl/intranet-freelance-procs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures to implement freelancer specific functions:
    - Freelance Database
    - Freelance Quality Evaluation
    - Freelance "Marketplace"

    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Constant functions
# ----------------------------------------------------------------------

ad_proc -public im_freelance_recruiting_status_potential {} { return 6000 }
ad_proc -public im_freelance_recruiting_status_test_sent {} { return 6002 }
ad_proc -public im_freelance_recruiting_status_test_received {} { return 6004 }
ad_proc -public im_freelance_recruiting_status_rest_evaluated {} { return 6006 }

ad_proc -public im_freelance_recruiting_test_result_a {} { return 6100 }
ad_proc -public im_freelance_recruiting_status_result_b {} { return 6102 }
ad_proc -public im_freelance_recruiting_status_result_c {} { return 6104 }


# ----------------------------------------------------------------------
# Permissions
# ----------------------------------------------------------------------

ad_proc -public im_freelance_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set current_user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
    set current_user_is_employee_p [im_user_is_employee_p $current_user_id]
    set current_user_admin_p [expr $current_user_is_admin_p || $current_user_is_wheel_p]

    set user_is_customer_p [ad_user_group_member [im_customer_group_id] $user_id]
    set user_is_freelance_p [ad_user_group_member [im_freelance_group_id] $user_id]
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
    set user_is_employee_p [im_user_is_employee_p $user_id]

    # Determine the type of the user to view:
    set user_type "none"
    if {$user_is_freelance_p} { set user_type "freelance" }
    if {$user_is_employee_p} { set user_type "employee" }
    if {$user_is_customer_p} { set user_type "customer" }
    if {$user_is_wheel_p} { set user_type "wheel" }
    if {$user_is_admin_p} { set user_type "admin" }


if { 0} {

    # Check if "user" belongs to a group that is administered by 
    # the current users
    set administrated_user_ids [db_list administated_user_ids "
select distinct
	m2.user_id
from
	user_group_map m,
	user_group_map m2
where
	m.user_id=:current_user_id
	and m.role='administrator'
	and m.group_id=m2.group_id
"]

    set user_in_administered_project 0
    if {[lsearch -exact $administrated_user_ids $user_id] > -1} { 
	set user_in_administered_project 1
    }

    # -------------- Permission Matrix ----------------

    # permission_matrix = [$view_user $edit_user]
    set permission_matrix [im_user_permission_matrix $current_user_id $user_id $user_type $current_user_admin_p $user_in_administered_project]
    set view_user [lindex $permission_matrix 0]
    set edit_user [lindex $permission_matrix 1]
    set show_admin_links $current_user_admin_p


    # Create an error if the current_user isn't allowed to see the user
    if {!$edit_user} {
	ad_return_complaint "[_ intranet-freelance.lt_Insufficient_Privileg]" "
    <li>[_ intranet-freelance.lt_You_have_insufficient]"
	return
    }

}
    set view 1
    set read 1
    set write 1
    set admin 1

    return
}


ad_proc -public im_user_skill_permissions { current_user_id user_id view_var read_var write_var admin_var } {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0
   
    im_user_permissions $current_user_id $user_id view read write admin
}


# $languages_html<BR>
# $freelance_html<BR>

# ----------------------------------------------------------------------
# Freelance Info Component
# Some simple extension data for freelancers
# ----------------------------------------------------------------------

ad_proc im_freelance_info_component { current_user_id user_id return_url freelance_view } {
    Show some simple information about a freelancer
} {
    set view 0
    set read 0
    set write 0
    set admin 0
    
    set user $user_id
    im_user_permissions $current_user_id $user_id view read write admin

    set freelance_member_p [db_string freelance_member "select count(1) from group_distinct_member_map where member_id=:user_id and group_id = [im_freelance_group_id]"]
    if {!$freelance_member_p} {
	# This is not a freelancer - skip showing the component
	return ""
    }

    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    
    set view_id [db_string get_view_id "select view_id from im_views where view_name=:freelance_view"]
    ns_log Notice "intranet-freelance: view_id=$view_id"

    set freelance_rates_sql "
	select	im_name_from_user_id(pe.person_id) as user_name,
		p.email,
		f.*,
		u.user_id,
		im_category_from_id (f.payment_method_id) as payment_method,
		im_category_from_id (f.rec_status_id) as rec_status,
		im_category_from_id (f.rec_test_result_id) as rec_test_result
	from	users u,
		im_freelancers f,
		parties p,
		persons pe
	where	pe.person_id = u.user_id
		and p.party_id = u.user_id
		and u.user_id = :user_id
		and u.user_id = f.user_id(+)
	"

    db_1row freelance_info_query $freelance_rates_sql

    set column_sql "
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
	order by sort_order"

   set freelance_html "
	<form method=POST action=/intranet-freelance/freelance-info-update>
	[export_form_vars user_id return_url]
	<table cellpadding=0 cellspacing=2 border=0>
	<tr> 
	  <td colspan=2 class=rowtitle align=center>[_ intranet-freelance.lt_Freelance_Information]</td>
	</tr>\n"

    set ctr 1
    # if the row makes references to "private Note" and the user isn't
    # adminstrator, this row don't appear in the browser.
    db_foreach column_list_sql $column_sql {
        if {1 || [eval $visible_for]} {
	    if { ![string equal "Private Note" $column_name] || $admin} {
	        append freelance_html "
                <tr $td_class([expr $ctr % 2])>
		<td>$column_name &nbsp;</td><td>"
	        set cmd "append freelance_html $column_render_tcl"
	        eval $cmd
	        append freelance_html "</td></tr>\n"
		incr ctr
	    }
        }
    }

    if {$admin } {
        append freelance_html "
        <tr $td_class([expr $ctr % 2])>
        <td></td><td><input type=submit value='[_ intranet-freelance.Edit]'></td></tr>\n"
    }
    append freelance_html "</table></form>\n"

    return $freelance_html
}


# ---------------------------------------------------------------
# Freelance Skills Component
# ---------------------------------------------------------------

ad_proc im_freelance_skill_component { current_user_id user_id  return_url} {
    Show some simple information about a freelancer
} {
    set view 0
    set read 0
    set write 0
    set admin 0

    im_user_permissions $current_user_id $user_id view read write admin
    if {!$read} { 
	ns_log Notice "im_freelance_skill_component: not allowed to read - exiting"
	return "" 
    }

    # Skip this component if the user is not a freelancer
    if {![ad_user_group_name_member "Freelancers" $user_id]} { 
	return "" 
    }


    # Check permissions to see and modify freelance skills and their confirmations
    #
    set view_freelance_skills_p [im_permission $current_user_id view_freelance_skills]
    set add_freelance_skills_p [im_permission $current_user_id add_freelance_skills]
    set view_freelance_skillconfs_p [im_permission $current_user_id view_freelance_skillconfs]
    set add_freelance_skillconfs_p [im_permission $current_user_id add_freelance_skillconfs]

    set sql "
select
        sk.skill_id,
        im_category_from_id(sk.skill_id) as skill,
        c.category_id as skill_type_id,
        im_category_from_id(c.category_id) as skill_type,
	im_category_from_id(sk.claimed_experience_id) as claimed,
	im_category_from_id(sk.confirmed_experience_id) as confirmed,
	sk.claimed_experience_id,
	sk.confirmed_experience_id
from
        (select c.*
         from im_categories c
         where c.category_type = 'Intranet Skill Type'
         order by c.category_id
        ) c,
        (select *
         from im_freelance_skills
         where user_id = :user_id
         order by skill_type_id
        ) sk
where
        sk.skill_type_id(+) = c.category_id
order by
        c.category_id
    "

    # ------------- Freelance Skill Table Header -------------------------------

    set ctr 1
    set old_skill_type_id 0
    set skill_header_titles ""
    db_foreach column_list $sql {
	if {$old_skill_type_id != $skill_type_id} {
	    append skill_header_titles "
	<td align=center>
	  <b>$skill_type</b>
	</td>"
	    set old_skill_type_id $skill_type_id
	}
	incr ctr
    }
    set colspan $ctr

    set skill_header_html "
	<table cellpadding=0 cellspacing=2 border=0>
	<tr>
	  <td class=rowtitle align=center colspan=$colspan>[_ intranet-freelance.Skills]</td>
	</tr>
	<tr class=rowtitle>
	  $skill_header_titles
	</tr>\n"


    # ------------- Freelance Skill Table Body -------------------------------
    # A horizontal array of tables, each representing freelance skills

    # Setup the horizontal table start
    #
    set skill_body_html "
	<tr valign=top class=rowodd>
	  <td>
	    <table cellpadding=0 cellspacing=1 border=1 width=100%>
	    <tr class=roweven>
              <td>Skill</td>
              <td align=center>[_ intranet-freelance.Claim]</td>
            </tr>"

    set old_skill_type_id 0
    set primera 1
    set ctr 1

    # I make a comparation between Claimed and Confirmed
    # to generate a "tick" or not if confirmed is correct.
    db_foreach skill_body_html $sql {

	if {$primera == 1} { 
	    set old_skill_type_id $skill_type_id
	    set primera 0
	}

	if {$old_skill_type_id != $skill_type_id} {
	    append skill_body_html "
	</table>
	</td>
	<td>
	  <table cellpadding=0 cellspacing=0 border=1 width=100%>
	    <tr class=roweven>
              <td>[_ intranet-freelance.Skill]</td>
              <td align=center>[_ intranet-freelance.Claim]</td>
            </tr>"
	    set old_skill_type_id $skill_type_id
	    set ctr 1
	}

	# Display a tick or a cross, depending whether the claimed
	# experience is confirmed or not.
	#
	set confirmation ""
	if {$view_freelance_skillconfs_p} {
	    if {"" != $confirmed && ![string equal "Unconfirmed" $confirmed]} {
		if {$claimed_experience_id <= $confirmed_experience_id } {
		    set confirmation [im_gif tick]
		} else {
		    set confirmation [im_gif wrong]
		}
	    }
	}
	set experiences_html_eval "<td align=left>$claimed$confirmation</td></tr>\n\t"

	
	if {[string equal "" $skill]} {
	    append skill_body_html ""
	} else {
	    append skill_body_html "<tr><td>$skill</td>"
	    append skill_body_html "$experiences_html_eval"
	}
	incr ctr
    }
    append skill_body_html "</table></td></tr>\n\t"
    
    if { $write } {
	# ------------  we put buttons for each skill for change its.
	
	set languages_butons_html "<tr align=center>"
	set old_skill_type_id 0
	db_foreach column_list $sql {
	    if {$old_skill_type_id != $skill_type_id} {
		append languages_butons_html "
<td><form method=POST action=/intranet-freelance/skill-edit>
[export_form_vars user_id skill_type_id return_url]
<input type=submit value=Edit></form></td>"
                set old_skill_type_id $skill_type_id
            }
       }
    } else {
        set languages_butons_html ""
    }

    append languages_butons_html "</tr>\n\t"
    append languages_html "
$skill_header_html\n
$skill_body_html\n
$languages_butons_html
</table>"

    return $languages_html
}


# ---------------------------------------------------------------
# Freelance Member Select Component
# ---------------------------------------------------------------

# this proc is only used without quality module

ad_proc im_freelance_member_select_component { 
    object_id 
    return_url 
} {
    Component that returns a formatted HTML table that allows 
    to select freelancers according to the characteristics of
    the current project.

    ToDo: Remove translation specific code to make the component
    universally usable, also for "consulting" projects.
} {
    # Default Role: "Full Member"
    set default_role_id 1300

    # Enable RFQs?
    set enable_rfq_p 0

    set colspan 5
    if {$enable_rfq_p} { set colspan 6 }

    set source_lang_skill_type [db_string source_lang "select category_id from im_categories where category = 'Source Language' and category_type = 'Intranet Skill Type'" -default 0]
    set target_lang_skill_type [db_string target_lang "select category_id from im_categories where category = 'Target Language' and category_type = 'Intranet Skill Type'" -default 0]
    set subject_area_skill_type [db_string target_lang "select category_id from im_categories where category = 'Subject Type' and category_type = 'Intranet Skill Type'" -default 0]

    set project_source_lang [db_string source_lang "select substr(im_category_from_id(source_language_id), 1, 2) from im_projects where project_id = :object_id" -default 0]
    set project_target_langs [db_list target_langs "select '''' || substr(im_category_from_id(language_id), 1, 2) || '''' from im_target_languages where project_id = :object_id"]
    if {0 == [llength $project_target_langs]} { set project_target_langs [list "'none'"]}

    set freelance_sql "
select distinct
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name,
	im_name_from_user_id(u.user_id) as name,
	im_freelance_skill_list(u.user_id, :source_lang_skill_type) as source_langs,
	im_freelance_skill_list(u.user_id, :target_lang_skill_type) as target_langs,
	im_freelance_skill_list(u.user_id, :subject_area_skill_type) as subject_area
from
	cc_users u,
	(
		select	user_id
		from	im_freelance_skills
		where	skill_type_id = :source_lang_skill_type
			and substr(im_category_from_id(skill_id), 1, 2) = :project_source_lang

	) sls,
	(	
		select	user_id
		from	im_freelance_skills
		where	skill_type_id = :target_lang_skill_type
			and substr(im_category_from_id(skill_id), 1, 2) in ([join $project_target_langs ","])
	) tls
where
	1=1
	and sls.user_id = u.user_id
	and tls.user_id = u.user_id
order by
	user_name
"

    set freelance_header_html "
	<tr class=rowtitle>\n"
    if {$enable_rfq_p} {
	append freelance_header_html "
	  <td class=rowtitle>[lang::message::lookup "" intranet-freelance.Sel "Sel"]</td>\n"
    }
    append freelance_header_html "
	  <td class=rowtitle>[_ intranet-freelance.Freelance]</td>
	  <td class=rowtitle>[_ intranet-freelance.Source_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance.Target_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance.Subject_Area]</td>
	  <td class=rowtitle>[lang::message::lookup "" intranet-freelance.Sel "Sel"]</td>
	</tr>"
    
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set ctr 0
    set freelance_body_html ""
    db_foreach freelance $freelance_sql {
	append freelance_body_html "
	<tr$bgcolor([expr $ctr % 2])>\n"
	if {$enable_rfq_p} {
	    append freelance_header_html "
          <td><input type=checkbox name=invitee_id value=$user_id></td>\n"
	}
	append freelance_body_html "
	  <td><a href=users/view?[export_url_vars user_id]><nobr>$name</nobr></a></td>
	  <td>$source_langs</td>
	  <td>$target_langs</td>
	  <td>$subject_area</td>
          <td><input type=radio name=user_id_from_search value=$user_id></td>
	</tr>"
        incr ctr
    }

    if { $freelance_body_html == "" } {
	set freelance_body_html "<tr><td colspan=$colspan align=center><b>[_ intranet-freelance.no_freelancers]</b></td>"
    }

    set freelance_invite_html ""
    if {$enable_rfq_p} {
        append freelance_invite_html "
	    [lang::message::lookup "" intranet-freelance.Invite_for_RFQ "Invite to RFQ"]<br>
	    <input type=submit name=submit_invite value=\"[lang::message::lookup "" intranet-freelance.Invite "Invite"]\">
        "
    }
    
    set select_freelance "
	<form method=POST action=/intranet/member-add-2>
	[export_entire_form]
	<input type=hidden name=target value=[im_url_stub]/member-add-2>
	<input type=hidden name=passthrough value='object_id role return_url also_add_to_group_id'>
	<table cellpadding=0 cellspacing=2 border=0>
	<tr>
	<td class=rowtitle align=middle colspan=$colspan>Freelance</td>
	</tr>
	$freelance_header_html
	$freelance_body_html
	  <tr> 
	    <td colspan=$colspan>

		<table cellspacing=0 cellpadding=0 width=\"100%\">
		<tr valign=top>
		<td width=\"50%\">
			$freelance_invite_html
		</td>
		<td width=\"50%\" align=right>
"
    if {$ctr > 0} {
	append select_freelance "
		      [_ intranet-core.add_as]
		      [im_biz_object_roles_select role_id $object_id $default_role_id]<br>
		      <input type=submit name=submit_add value=\"[_ intranet-core.Add]\">
		      <input type=checkbox name=notify_asignee value=1 checked>[_ intranet-freelance.Notify]<br>
        "
    }

    append select_freelance "
		</td>
		</tr>
		</table>

	    </td>
	  </tr>
	</table>
	</form>
"


return $select_freelance
}

