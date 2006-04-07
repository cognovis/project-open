# /tcl/intranet-simple-survey-procs.tcl
#
# Copyright (C) 2003-2006 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Associate Simple Surveys with ]po[ business objects 
    and allow to manage their relationship and recurrence.

    @author frank.bergmann@project-open.com
    @creation-date  January 3rd, 2006
}


# -----------------------------------------------------------
# Standard procedures
# -----------------------------------------------------------

ad_proc -public im_package_survsimp_id { } {
} {
    return [util_memoize "im_package_survsimp_id_helper"]
}

ad_proc -private im_package_survsimp_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-simple-survey'
    } -default 0]
}


# -----------------------------------------------------------
# Standard procedures
# -----------------------------------------------------------

ad_proc im_survsimp_component { object_id } {
    Shows al associated simple surveys for a given project or company
} {
    set bgcolor(0) "class=roweven"
    set bgcolor(1) "class=rowodd"
    set survey_url "/simple-survey/one"

    set current_user_id [ad_get_user_id]

    # Get information about object type
    db_1row object_type_info "
	select	aot.*,
		aot.pretty_name as aot_pretty_name,
		im_biz_object__type(:object_id) as object_type_id
	from	acs_object_types aot
	where	object_type = (
			select object_type 
			from acs_objects 
			where object_id = :object_id
		)
    "

    set survsimp_sql "
	select
		som.*,
		som.name as som_name,
		som.note as som_note,
		ss.*
	from
		im_survsimp_object_map som,
		survsimp_surveys ss
	where
		som.survey_id = ss.survey_id
		and som.acs_object_type = :object_type
		and (
			som.biz_object_type_id is null
			OR som.biz_object_type_id = :object_type_id 
		    )
		and im_object_permission_p(ss.survey_id, :current_user_id, 'survsimp_take_survey') = 't'
    "

    set simple_surveys_l10n [lang::message::lookup "" intranet-simple-survey.${aot_pretty_name}_Surveys "$aot_pretty_name Surveys"]

    set survsimp_html ""
    set ctr 0
    db_foreach survsimp_map $survsimp_sql {

	set som_gif ""
	if {"" != $som_note} {set som_gif [im_gif help $som_note]}
	append survsimp_html "
	    <tr $bgcolor([expr $ctr % 2])>
		<td><a href=\"$survey_url?survey_id=$survey_id\">$short_name</a></td>
		<td>$som_name $som_gif</td>
	    </tr>
	"
	incr ctr
    }

    if {0 == $ctr} { 
	set survsimp_html "
	    <tr $bgcolor([expr $ctr % 2])>
		<td colspan=2>[lang::message::lookup "" intranet-simple-survey.There_are_no_surveys_for_this_object "There are no surveys available for this object"]</td>
	    </tr>
	"
    }

    set survsimp_html "
	<table>
	  <tr class=rowtitle>
		<td>Survey</td>
		<td>Comment</td>
	  </tr>
	  $survsimp_html
	</table>
    "

    return [im_table_with_title $simple_surveys_l10n $survsimp_html]
}

