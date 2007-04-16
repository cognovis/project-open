# /packages/intranet-freelance-translation/tcl/intranet-freelance-translation-procs.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures to implement translation freelancer functions:
    @author frank.bergmann@project-open.com
}


# ---------------------------------------------------------------
# Freelance Translation Member Select Component
# ---------------------------------------------------------------

# this proc is only used without quality module

ad_proc im_freelance_trans_member_select_component { 
    object_id 
    return_url 
} {
    Component that returns a formatted HTML table that allows 
    to select freelancers according to the characteristics of
    the current project.
} {
    # ------------------------------------------------
    # Security
    set user_id [ad_get_user_id]
    if {![im_project_has_type $object_id "Translation Project"] || ![im_permission $user_id view_trans_proj_detail]} {
        return ""
    }

    # ------------------------------------------------
    # Constants

    # Default Role: "Full Member"
    set default_role_id 1300
    
    # How many static columns?
    set colspan 5

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "

    set source_lang_skill_type [db_string source_lang "
		select	category_id 
		from	im_categories 
		where	category = 'Source Language' 
			and category_type = 'Intranet Skill Type'" \
    -default 0]
    set target_lang_skill_type [db_string target_lang "
		select	category_id	
		from	im_categories	
		where	category = 'Target Language'
			and category_type = 'Intranet Skill Type'" \
    -default 0]
    set subject_area_skill_type [db_string target_lang "
		select	category_id	
		from	im_categories	
		where	category = 'Subject Type' 
			and category_type = 'Intranet Skill Type'" \
    -default 0]
    set project_source_lang [db_string source_lang "
		select	substr(im_category_from_id(source_language_id), 1, 2) 
		from	im_projects 
		where	project_id = :object_id" \
    -default 0]

    set project_target_langs [db_list target_langs "
		select '''' || substr(im_category_from_id(language_id), 1, 2) || '''' 
		from	im_target_languages 
		where	project_id = :object_id
    "]
    if {0 == [llength $project_target_langs]} { set project_target_langs [list "'none'"]}

    # ------------------------------------------------
    # Put together the main SQL

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


    # ------------------------------------------------
    # Determine the price ranges per freelancer
    set price_sql "
	select
		f.user_id,
		c.company_id,
		p.uom_id,
		min(p.price) as min_price,
		max(p.price) as max_price
	from
		($freelance_sql) f
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
	set med_price_hash($key) [expr ($min_price + $max_price) / 2.0]
	set price_hash($key) "$min_price - $max_price"
	if {$min_price == $max_price} { set price_hash($key) "$min_price" }
    }

    set uom_listlist [db_list_of_lists uom_list "
	select uom_id, im_category_from_id(uom_id)
	from (select distinct uom_id from ($price_sql) t) t
	order by uom_id
    "]


    # ------------------------------------------------
    # Mix Freelance Info with Prices

    # Sort by S-Word
    set sort_uom_id 324

    set table_rows [list]
    db_foreach freelance $freelance_sql {
	set row [list $user_id $name $source_langs $target_langs $subject_area]

	# sort_val - value for sorting the table
	set sort_val 999999999999
	set key "$user_id-$sort_uom_id"
	if {[info exists med_price_hash($key)]} { set sort_val $med_price_hash($key) }
	lappend row $sort_val

	lappend table_rows $row
    }


    # Sort the keys according to sort_val (6th element)
    set sorted_table_rows [qsort $table_rows [lambda {s} { lindex $s 5 }]]

    # ------------------------------------------------
    # Format the table header

    set freelance_header_html "
	<tr class=rowtitle>
	  <td class=rowtitle>[_ intranet-freelance.Freelance]</td>
	  <td class=rowtitle>[_ intranet-freelance.Source_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance.Target_Language]</td>
	  <td class=rowtitle>[_ intranet-freelance.Subject_Area]</td>
    "
    foreach uom_tuple $uom_listlist {
        append freelance_header_html "<td class=rowtitle>[lindex $uom_tuple 1]</td>\n"
	incr colspan
    }
    append freelance_header_html "
	  <td class=rowtitle>[lang::message::lookup "" intranet-freelance.Sel "Sel"]</td>
	</tr>
    "

    # ------------------------------------------------
    # Format the table body

    set ctr 0
    set freelance_body_html ""
    foreach freelance_row $sorted_table_rows {

        set user_id [lindex $freelance_row 0]
	set name [lindex $freelance_row 1]
	set source_langs [lindex $freelance_row 2]
	set target_langs [lindex $freelance_row 3]
	set subject_area [lindex $freelance_row 4]
	
	append freelance_body_html "
	<tr$bgcolor([expr $ctr % 2])>\n"

	append freelance_body_html "
	  <td><a href=users/view?[export_url_vars user_id]><nobr>$name</nobr></a></td>
	  <td>$source_langs</td>
	  <td>$target_langs</td>
	  <td>$subject_area</td>
        "

	foreach uom_tuple $uom_listlist {
	    set uom_id [lindex $uom_tuple 0]
	    set key "$user_id-$uom_id"
	    set val ""
	    if {[info exists price_hash($key)]} { set val $price_hash($key) }
	    append freelance_body_html "<td>$val</td>\n"
	}

	append freelance_body_html "
          <td><input type=radio name=user_id_from_search value=$user_id></td>
	</tr>"
        incr ctr
    }

    if { $freelance_body_html == "" } {
	set freelance_body_html "<tr><td colspan=$colspan align=center><b>[_ intranet-freelance.no_freelancers]</b></td>"
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
		<td width=\"50%\"></td>
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

