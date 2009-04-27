# /packages/intranet-freelance-rfqs/www/new-rfq-2.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    Add / edit freelance-rfqs in project
} {
    rfq_id:integer
    return_url
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
if {![im_permission $current_user_id "view_freelance_rfqs"]} {

    # The current user doesn't have permissions to see _RFQs_
    # However, the user might have been invited to fill out an RFQ _Answer_
    set invited_p [db_string invited "
	select	count(*) 
	from	im_freelance_rfq_answers
	where	answer_rfq_id = :rfq_id 
		and answer_user_id = :current_user_id
    "]
    if {$invited_p} { ad_returnredirect [export_vars -base "new-answer" {rfq_id return_url}] }

    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    ad_script_abort
}

set page_title [lang::message::lookup "" intranet-freelance-rfqs.RFQ_Base_Data "RFQ Base Data"]
set context_bar [im_context_bar $page_title]
set action_url "/intranet-freelance-rfqs/new-rfq"
set user_url_base "/intranet/users/view"

set rfq_project_id [db_string pid "select rfq_project_id from im_freelance_rfqs where rfq_id = :rfq_id" -default 0]

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set todays_time [lindex [split [ns_localsqltimestamp] " "] 1]

set add_freelance_rfqs_p [im_permission $current_user_id "add_freelance_rfqs"]

# Display the list of following types to add to the RFQ
# set active_skill_types [list 2000 2002 2004 2014]
# 2000 = Source Language 2002 = Target Language 2014 = Subjects 
# 2010 = OS 2004 = Sworn Language  2006 = TM Tools 2008 = LOC Tools

# Update from Ben Taylor: Use all skills
set active_skill_types [db_list skill_types "
        select  category_id
        from    im_categories
        where   category_type = 'Intranet Skill Type'
        order by category_id
"]




# Default level required
set default_experience_level 2200
# 2203 High
# 2201 Low
# 2202 Medium
# 2200 Unconfirmed

set default_skill_weight 2402

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

# Return_URL to this page.
set return_url2 [im_url_with_query]

set source_lang_skill_type [db_string source_lang "select category_id from im_categories where category = 'Source Language' and category_type = 'Intranet Skill Type'" -default 0]
set target_lang_skill_type [db_string target_lang "select category_id from im_categories where category = 'Target Language' and category_type = 'Intranet Skill Type'" -default 0]
set subject_area_skill_type [db_string target_lang "select category_id from im_categories where category = 'Subjects' and category_type = 'Intranet Skill Type'" -default 0]


# ------------------------------------------------------------------
# Form Options
# ------------------------------------------------------------------


set freelance_rfq_type_options [db_list_of_lists freelance_rfq_type "
	select	freelance_rfq_type, 
		freelance_rfq_type_id 
	from	im_freelance_rfq_type
"]
set freelance_rfq_type_options [linsert $freelance_rfq_type_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]

set freelance_rfq_status_options [db_list_of_lists freelance_rfq_status "
	select	freelance_rfq_status,
		freelance_rfq_status_id
	from	im_freelance_rfq_status
"]
set freelance_rfq_status_options [linsert $freelance_rfq_status_options 0 [list [lang::message::lookup "" "intranet-freelance-rfqs.--Select--" "-- Please Select --"] 0]]

set uom_options [im_cost_uom_options]


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "freelance_rfq"
set focus "$form_id\.var_name"
set form_mode "display"


ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {rfq_project_id return_url} \
    -form {
	rfq_id:key
	{rfq_name:text(text) {label "[_ intranet-freelance-rfqs.Name]"} {html {size 40}}}
	{rfq_type_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.RFQ_Type]"}
	    {options $freelance_rfq_type_options} 
	}
	{rfq_status_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.RFQ_Status]"}
	    {options $freelance_rfq_status_options} 
	}

	{rfq_start_date:date(date) {label "[_ intranet-freelance-rfqs.Start_date]"} }
	{rfq_end_date:date(date) {label "[_ intranet-freelance-rfqs.End_date]"} {format "DD Month YYYY HH24:MI"} }

	{rfq_units:text(text),optional {label "[_ intranet-freelance-rfqs.Units]"} {html {size 6}}}
	{rfq_uom_id:text(select) 
	    {label "[_ intranet-freelance-rfqs.UoM]"}
	    {options $uom_options} 
	}
    }

if {![info exists rfq_type_id]} { set rfq_type_id "" }
im_dynfield::append_attributes_to_form \
    -object_type "im_freelance_rfq" \
    -object_subtype_id $rfq_type_id \
    -form_id $form_id \
    -form_display_mode "display"


ad_form -extend -name $form_id -form {
	{rfq_description:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Description Description]"} {html {cols 40}}}
	{rfq_note:text(textarea),optional {label "[lang::message::lookup {} intranet-freelance-rfqs.Note Note]"} {html {cols 40}}}
    }


# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------


ad_form -extend -name $form_id -on_request {

    # Populate elements from local variables


} -select_query {

	select	*,
		to_char(rfq_start_date, 'YYYY MM DD') as rfq_start_date,
		to_char(rfq_end_date, 'YYYY MM DD HH24 MI') as rfq_end_date
	from	im_freelance_rfqs
	where	rfq_id = :rfq_id

} -on_submit {
    
    ns_log Notice "on_submit"
    
} -after_submit {

    set next_url [export_vars -base "new-rfq-2" {return_url rfq_id}]
    ad_returnredirect $next_url
    ad_script_abort
}


# Set default values for start and end date - if form is ""
if {"" == [template::element::get_value $form_id rfq_start_date]} {
    set start_date_list [split $todays_date "-"]
    set start_date_list [concat $start_date_list [split $todays_time ":"]]
    template::element::set_value $form_id rfq_start_date $start_date_list
}

if {"" == [template::element::get_value $form_id rfq_end_date]} {
    set end_date_list [split $todays_date "-"]
    set end_date_list [concat $end_date_list [split $todays_time ":"]]
    template::element::set_value $form_id rfq_end_date $end_date_list
}
    


# ------------------------------------------------------------------
# Show skills
# ------------------------------------------------------------------

set actions_list [list]
set bulk_actions_list [list]

if {[im_permission $current_user_id "add_freelance_rfqs"]} {
    set delete_msg [lang::message::lookup "" intranet-freelance-rfqs.Delete_Skill "Delete"]
    lappend bulk_actions_list $delete_msg "del-rfq-skills" $delete_msg
}

set export_var_list [list return_url]
set list_id "skill_list"

template::list::create \
    -name $list_id \
    -multirow skill_list_lines \
    -key object_skill_map_id \
    -has_checkboxes \
    -actions $actions_list \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	rfq_id
	{ return_url $return_url2 }
    } \
    -row_pretty_plural "[_ intranet-freelance-rfqs.RFQs_Items]" \
    -elements {
	rfq_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" onclick=\"acs_ListCheckAll('skills_list', this.checked)\" title=\"Check/uncheck all rows\">"
	    display_template {
		@skill_list_lines.skill_chk;noquote@
	    }
	}
	skill_type {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.Skill_Type {Skill Type}]"
	}
	skill {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.Skill {Skill}]"
	}
	experience {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.Experience {Experience}]"
	}
	skill_weight {
	    label "[lang::message::lookup {} intranet-freelance-rfqs.Weight {Weight}]"
	}
    }


db_multirow -extend {skill_chk skill_new_url} skill_list_lines skills "
	select	*,
		im_category_from_id(skill_id) as skill,
		im_category_from_id(skill_type_id) as skill_type,
		im_category_from_id(required_experience_id) as experience
	from	im_object_freelance_skill_map m
	where	m.object_id = :rfq_id
	order by skill_type_id,	skill_id
" {
    set skill_chk "<input type=checkbox name=object_skill_map_ids value=$object_skill_map_id id='skills_list,$object_skill_map_id'>"
    set rfq_new_url [export_vars -base "/rfc-new-skill" {skill_id return_url}]

    if {"" == $experience} { set experience [lang::message::lookup "" intranet-freelance-rfqs.Optional "Optional"] }

}


# ---------------------------------------------------------------
# Add Required Skills to RFQ
# ---------------------------------------------------------------

set ctr 0
set add_skill_trs ""
foreach skill_type_id $active_skill_types {

    append add_skill_trs "
	<tr$bgcolor([expr $ctr % 2])>
	  <td>[im_category_from_id -translate_p 0 $skill_type_id]</td>
	  <td>[im_freelance_skill_select skill_ids.$skill_type_id $skill_type_id ""]</td>
	  <td>[im_category_select_plain -include_empty_p 1 -include_empty_name "Optional" "Intranet Experience Level" exp_ids.$skill_type_id $default_experience_level]</td>
	  <td>[im_category_select_plain -include_empty_p 0 "Intranet Skill Weight" weight_ids.$skill_type_id $default_skill_weight]</td>
	</tr>
    "
    incr ctr
}



# ------------------------------------------------------------------
# Determine the price ranges per freelancer
# ------------------------------------------------------------------

set freelance_sql "
        select distinct
                u.user_id,
                im_name_from_user_id(u.user_id) as user_name,
                im_name_from_user_id(u.user_id) as name,
                im_freelance_skill_list(u.user_id, :source_lang_skill_type) as source_langs,
                im_freelance_skill_list(u.user_id, :target_lang_skill_type) as target_langs,
                im_freelance_skill_list(u.user_id, :subject_area_skill_type) as subject_area
        from
                cc_users u
        where	1=1
"

# 070812 fraber: replaced "($freelance_sql) f" by "users f"

set price_sql "
        select
                f.user_id,
                c.company_id,
                p.uom_id,
                min(p.price) as min_price,
                max(p.price) as max_price
        from
                users f
                LEFT OUTER JOIN acs_rels uc_rel
                        ON (f.user_id = uc_rel.object_id_two)
                LEFT OUTER JOIN im_trans_prices p
                        ON (uc_rel.object_id_one = p.company_id),
                im_companies c
        where
                p.company_id = c.company_id
        group by
                f.user_id,
                c.company_id,
                p.uom_id
"

db_foreach price_hash $price_sql {
    set key "$user_id-$uom_id"
    set price_hash($key) "$min_price - $max_price"
    if {$min_price == $max_price} { set price_hash($key) "$min_price" }
}

set uom_listlist [db_list_of_lists uom_list "
        select uom_id, im_category_from_id(uom_id)
        from (select distinct uom_id from ($price_sql) t) t
        order by uom_id
"]


# ------------------------------------------------------------------
# Show list of Candidates and Manage invitations and workflow
# ------------------------------------------------------------------

set actions_list [list]
set bulk_actions_list [list]

if {[im_permission $current_user_id "add_freelance_rfqs"]} {
    set invite_participants_msg [lang::message::lookup "" intranet-freelance-rfqs.Invite_Participants "Invite Participants"]
    lappend bulk_actions_list $invite_participants_msg "invite-rfq-members" $invite_participants_msg
    
    set confirm_invitations_msg [lang::message::lookup "" intranet-freelance-rfqs.Confirm_RFQ "Confirm RFQ"]
    lappend bulk_actions_list $confirm_invitations_msg "confirm-rfq-members" $confirm_invitations_msg
    
    set decline_invitations_msg [lang::message::lookup "" intranet-freelance-rfqs.Decline_RFQ "Decline RFQ"]
    lappend bulk_actions_list $decline_invitations_msg "decline-rfq-members" $decline_invitations_msg
}

set elements {
	rfq_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" \
		  onclick=\"acs_ListCheckAll('candidates_list', this.checked)\" \
		  title=\"Check/uncheck all rows\">"
	    display_template {
		@candidate_list_lines.candidate_chk;noquote@
	    }
	}
	score {	label "[lang::message::lookup {} intranet-freelance-rfqs.Score {Score}]" }
	user_name {	
	    label "[lang::message::lookup {} intranet-freelance-rfqs.User {User}]"
	    link_url_eval $user_url
	}
}

lappend elements answer_status
lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.Answer_Status {Status}]" }


# lappend elements source_langs 
# lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.All_Source_Languages {All Sourc Langs}]" }
# lappend elements target_langs 
# lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.All_Target_Languages {All Target Langs}]" }
# lappend elements subject_areas 
# lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.Subject_Areas {Subject Areas}]" }



# -------------------------------------------------------------
# Add columns for each skill:
#	- in SQL to extract "claimed experience"
#	- in SQL to extract "confirmed experience"
#	- in SQL to limit

set skill_sql "
	select	*,
		im_category_from_id(skill_id) as skill,
		im_category_from_id(skill_type_id) as skill_type
	from	im_object_freelance_skill_map m
	where	m.object_id = :rfq_id
"
db_multirow skills skills $skill_sql 

set extend_list {candidate_chk user_url score note answer_accepted price}
set skill_select_sql ""
set skill_where_sql ""
template::multirow foreach skills {
    append skill_select_sql "
	,(	select	s.claimed_experience_id
		from	im_freelance_skills s
		where	user_id = u.user_id
			and s.skill_type_id = $skill_type_id
			and s.skill_id = $skill_id
	) as u$object_skill_map_id
    "
    append skill_select_sql "
	,(	select	s.confirmed_experience_id
		from	im_freelance_skills s
		where	user_id = u.user_id
			and s.skill_type_id = $skill_type_id
			and s.skill_id = $skill_id
	) as c$object_skill_map_id
    "

    if {"" != $required_experience_id} {
        append skill_where_sql "
		and u.user_id in (
			select	user_id
			from	im_freelance_skills s
			where	s.skill_type_id = $skill_type_id
				and s.skill_id = $skill_id
				and confirmed_experience_id >= $required_experience_id
		)
        "
    }

    set skill_key [lang::util::suggest_key $skill]
    set skill_l10n [lang::message::lookup "" intranet-core.$skill_key $skill]
    set skill_type_key [lang::util::suggest_key $skill_type]
    set skill_type_l10n [lang::message::lookup "" intranet-core.$skill_type_key $skill_type]
    set label [lang::message::lookup {} intranet-freelance-rfqs.${skill_type_l10n}_${skill_l10n} "$skill_type_l10n<br>$skill_l10n"]

    lappend extend_list "s$object_skill_map_id"

    lappend elements "s$object_skill_map_id"
    lappend elements [list label $label display_template "@candidate_list_lines.s$object_skill_map_id;noquote@"]

}


lappend elements answer_accepted
lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.Answer_Accepted {Accepted?}]" }



lappend elements price
lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.Price {Price}]" }



# ------------------------------------------------------------
# Add the DynFields from im_freelance_rfq_answers

set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name,
		aa.pretty_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_freelance_rfq_answer'
"
db_foreach column_list_sql $column_sql {

    # Select another field
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"

    # Show this field in the template::list
    lappend elements ${attribute_name}_deref
    lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.$attribute_name $pretty_name]" }

}
set extra_select [join $extra_selects ",\n\t"]

lappend elements answer_note 
lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.Note {Note}]" }



# -------------------------------------------------------------
# Define the list view

set export_var_list [list rfq_id return_url]
set list_id "candidate_list"

template::list::create \
    -name $list_id \
    -multirow candidate_list_lines \
    -key object_candidate_map_id \
    -has_checkboxes \
    -actions $actions_list \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	rfq_id
	{ return_url $return_url2 }
    } \
    -row_pretty_plural "[_ intranet-freelance-rfqs.RFQs_Items]" \
    -elements $elements



db_multirow -extend $extend_list candidate_list_lines candidates "
	select
		a.*,
		u.user_id,
		im_category_from_id(a.answer_status_id) as answer_status,
		im_name_from_user_id(u.user_id) as user_name,
		im_freelance_skill_list(u.user_id, :source_lang_skill_type) as source_langs,
		im_freelance_skill_list(u.user_id, :target_lang_skill_type) as target_langs,
		im_freelance_skill_list(u.user_id, :subject_area_skill_type) as subject_areas,
		$extra_select
		$skill_select_sql
	from
		cc_users u
		LEFT OUTER JOIN im_freelance_rfq_answers a ON (
			a.answer_user_id = u.user_id
			and a.answer_rfq_id = :rfq_id
		)
	where
		1=1
		$skill_where_sql
" {
    set candidate_chk "<input type=checkbox name=user_ids value=$user_id id='candidates_list,$user_id'>"
    set user_url [export_vars -base $user_url_base {user_id}]

    switch $answer_accepted_p {
	t { set answer_accepted "Accept" }
	f { set answer_accepted "Decline" }
	default { set answer_accepted "?" }
    }

    set note ""
    set score 0

    # Check the skill levels for all required skills
    db_foreach skills $skill_sql {

	# Check freelancer's skill level and kick the guy out if he doesn't meet the criteria
	set confirmed_exp_id [expr "\$c$object_skill_map_id"]
	set claimed_exp_id [expr "\$u$object_skill_map_id"]

	if {"" == $claimed_exp_id } { set claimed_exp_id $confirmed_exp_id }
	if {"" == $confirmed_exp_id } { set confirmed_exp_id 2200 }

	set exp_id $claimed_exp_id
	if {$confirmed_exp_id < $exp_id} { set exp_id $confirmed_exp_id}

	set exp [im_category_from_id $exp_id]

	set exp_weight [db_string confweight "select aux_int1 from im_categories where category_id = :exp_id" -default 1]

	if {"" != $exp} {
#	    ad_return_complaint 1 "oskill_map_id=$object_skill_map_id, exp_id=$exp_id, exp_weight=$exp_weight, exp=$exp"
	}

	if {"" == $exp_weight} { 
	    ad_return_complaint 1 "Configuration Error:<br>
	    The administrator needs to configure the category '$exp' and assign a 'exp_weight' value (1-10) to 'aux_int1'"
	    ad_script_abort
	}

	if {$exp_id >= $required_experience_id} { set add [expr $skill_weight * $exp_weight] }

	set skill_var "s$object_skill_map_id"
	set $skill_var "$exp"

	set price ""
	foreach uom_entry $uom_listlist {
	    set uom_id [lindex $uom_entry 0]
	    set uom [lindex $uom_entry 1]

	    set key "$user_id-$uom_id"
	    if {[info exists price_hash($key)]} {
		append price $price_hash($key)
	    }
	}

	set score [expr $score + $add]

    }
}

template::multirow sort candidate_list_lines -integer -decreasing score


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set project_id [db_string rfq_project "select rfq_project_id from im_freelance_rfqs where rfq_id = :rfq_id" -default 0]
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_freelance_rfqs"]

