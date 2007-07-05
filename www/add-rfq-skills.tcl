# /packages/intranet-freelance-rfqs/www/add-rfq-skills.tcl
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
    @param project_id
} {
    rfq_id:integer
    skill_ids:array
    exp_ids:array
    weight_ids:array
    return_url
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id "add_freelance_rfqs"]} {
    ad_return_complaint 1 "[_ intranet-timesheet2-invoices.lt_You_have_insufficient_1]"
    return
}

set page_title [lang::message::lookup "" intranet-freelance-rfqs.Freelance_RFQ "Freelance-RFQs"]
set context_bar [im_context_bar $page_title]
set action_url "/intranet-freelance-rfqs/new-rfq"


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------


foreach skill_type_id [array names skill_ids] {

    set skill_id $skill_ids($skill_type_id)
    if {"" == $skill_id} { continue }

    set exp_id $exp_ids($skill_type_id)
    set weight_id $weight_ids($skill_type_id)
    set weight [db_string weight "select aux_int1 from im_categories where category_id=:weight_id" -default ""]
    if {"" == $weight} { set weight 1 }

    set exists_p [db_string count "
	select	count(*) 
	from	im_object_freelance_skill_map 
	where	object_id = :rfq_id
		and skill_type_id = :skill_type_id
		and skill_id = :skill_id
    "]

    if {$exists_p} {
	db_dml delete "
		delete from im_object_freelance_skill_map
		where
			object_id = :rfq_id
			and skill_type_id = :skill_type_id
			and skill_id = :skill_id
	"
    }


	db_dml insert "
	insert into im_object_freelance_skill_map (
		object_skill_map_id,
		object_id,
		skill_type_id,
		skill_id,
		experience_id,
		skill_weight,
		skill_required_p
	) values (
		nextval('im_object_freelance_skill_seq'),
		:rfq_id,
		:skill_type_id,
		:skill_id,
		:exp_id,
		:weight,
		't'
	)"


    if {!$exists_p} {    }
}

ad_returnredirect $return_url
