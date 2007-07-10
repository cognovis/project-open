
# /packages/intranet-freelance-rfqs/tcl/intranet-freelance-rfqs-procs.tcl
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


# ---------------------------------------------------------------
# Constants
# ---------------------------------------------------------------


ad_proc -public im_freelance_rfq_type_rfa {} { return 4400 }
ad_proc -public im_freelance_rfq_type_rfq {} { return 4402 }
ad_proc -public im_freelance_rfq_type_reverse_auction {} { return 4404 }

ad_proc -public im_freelance_rfq_status_open {} { return 4420 }
ad_proc -public im_freelance_rfq_status_closed {} { return 4422 }
ad_proc -public im_freelance_rfq_status_canceled {} { return 4424 }
ad_proc -public im_freelance_rfq_status_deleted {} { return 4426 }


ad_proc -public im_freelance_rfq_answer_type_default {} { return 4450 }

ad_proc -public im_freelance_rfq_answer_status_invited {} { return 4470 }
ad_proc -public im_freelance_rfq_answer_status_confirmed {} { return 4472 }
ad_proc -public im_freelance_rfq_answer_status_declined {} { return 4474 }
ad_proc -public im_freelance_rfq_answer_status_canceled {} { return 4476 }
ad_proc -public im_freelance_rfq_answer_status_closed {} { return 4478 }
ad_proc -public im_freelance_rfq_answer_status_deleted {} { return 4499 }



# ---------------------------------------------------------------
# Freelance Member Select Component
# ---------------------------------------------------------------

ad_proc im_freelance_rfq_member_select_component { object_id return_url } {
    Component that returns a formatted HTML table that allows 
    to select freelancers according to the characteristics of
    the current project.
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
select
	u.user_id,
	im_name_from_user_id(u.user_id) as name,
	im_freelance_rfq_skill_list(u.user_id, :source_lang_skill_type) as source_langs,
	im_freelance_rfq_skill_list(u.user_id, :target_lang_skill_type) as target_langs,
	im_freelance_rfq_skill_list(u.user_id, :subject_area_skill_type) as subject_area
from
	cc_users u,
	(
		select	user_id
		from	im_freelance_rfq_skills
		where	skill_type_id = :source_lang_skill_type
			and substr(im_category_from_id(skill_id), 1, 2) = :project_source_lang

	) sls,
	(	
		select	user_id
		from	im_freelance_rfq_skills
		where	skill_type_id = :target_lang_skill_type
			and substr(im_category_from_id(skill_id), 1, 2) in ([join $project_target_langs ","])
	) tls
where
	1=1
	and sls.user_id = u.user_id
	and tls.user_id = u.user_id
order by
	u.last_name,
	u.first_names
"

    set freelance_header_html "
	<tr class=rowtitle>\n"
    if {$enable_rfq_p} {
	append freelance_header_html "
	  <td class=rowtitle>[lang::message::lookup "" intranet-freelance-rfqs.Sel "Sel"]</td>\n"
    }
    append freelance_header_html "
	  <td class=rowtitle>[_ intranet-freelance-rfqs.Freelance]</td>
	  <td class=rowtitle>[_ intranet-freelance-rfqs.Source_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance-rfqs.Target_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance-rfqs.Subject_Area]</td>
	  <td class=rowtitle>[lang::message::lookup "" intranet-freelance-rfqs.Sel "Sel"]</td>
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
	set freelance_body_html "<tr><td colspan=$colspan align=center><b>[_ intranet-freelance-rfqs.no_freelancers]</b></td>"
    }

    set freelance_invite_html ""
    if {$enable_rfq_p} {
        append freelance_invite_html "
	    [lang::message::lookup "" intranet-freelance-rfqs.Invite_for_RFQ "Invite to RFQ"]<br>
	    <input type=submit name=submit_invite value=\"[lang::message::lookup "" intranet-freelance-rfqs.Invite "Invite"]\">
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
		      <input type=checkbox name=notify_asignee value=1 checked>[_ intranet-freelance-rfqs.Notify]<br>
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


# ---------------------------------------------------------------
# HTML Components
# ---------------------------------------------------------------

ad_proc -public im_freelance_rfq_select {
    {-include_empty 0}
    {-project_id 0}
    select_name
    {default ""}
} {
    Returns a select box with all applicable RFQs
} {

    set project_where ""
    if {0 != $project_id} { set project_where "project_id = :project_id\n" }
    set options [db_list_of_lists freelance_rfqs "
	select	rfq_name,
		rfq_id
	from	im_freelance_rfqs
	where	1=1
		$project_where
    "]

    if {[llength $options] == 1} {
        set entry [lindex $options 0]
        set id [lindex $entry 1]
        set name [string trim [lindex $entry 0]]
        return "$name <input type=hidden name=\"$select_name\" value=\"$id\">\n"
    }

    return [im_options_to_select_box $select_name $options $default]
}
