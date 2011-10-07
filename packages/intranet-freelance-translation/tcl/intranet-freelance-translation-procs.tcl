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

ad_proc im_freelance_trans_member_select_component_join_prices {
    hash
    params
} {
    Simplify the display of prices that are very similar to each other.
    This function checks if the two lists of price parameters only differ
    in at most 1 list element. In this case, it will join the two parameter
    lists by concatenating the one list element that is different.
    Otherwise it will just return two list elements.
} {
    # Check if this is the first price.
    if {"" == $hash} { return [list $params] }

    # Ok, there is at least one parameter list in the list "hash".
    # Split the list into its last element, and the first elements
    set hash_last [lindex $hash end]
    set hash_first [lrange $hash 0 end-1]

    # Compare the hash_last (simple!) list with the params simple list
    set len [llength $params]
    if {[llength $hash_last] > $len} { set len [llength $hash_last] }
    set diffs 0
    set param_idx -1
    for {set i 0} {$i < $len} {incr i} {
	if {[lindex $params $i] != [lindex $hash_last $i]} {
	    incr diffs
	    set param_idx $i
	}
    }

    if {1 == $diffs} {
	# Combine the two elements
	set result [list]
	for {set i 0} {$i < $len} {incr i} {
	    if {$i != $param_idx} {
		lappend result [lindex $params $i]
	    } else {
		lappend result "[lindex $hash_last $i] [lindex $params $i]"
	    }
	}
	lappend hash_first $result
	return $hash_first
    } else {
	# Just return the appended lists
	lappend hash_first $hash_last
	lappend hash_first $params
	return $hash_first
    }
}



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
    # Parameter Logic
    # 
    # Get the freel_trans_order_by variable from the http header
    # because we can't trust that the embedding page will pass
    # this param into this component.

    set current_url [ad_conn url]
    set header_vars [ns_conn form]
    set var_list [ad_ns_set_keys $header_vars]

    # set local TCL vars from header vars
    ad_ns_set_to_tcl_vars $header_vars

    # Remove the "freel_trans_order_by" from the var_list
    set order_by_pos [lsearch $var_list "freel_trans_order_by"]
    if {$order_by_pos > -1} {
	set var_list [lreplace $var_list $order_by_pos $order_by_pos]
    }

    if {![info exists freel_trans_order_by]} {
	set freel_trans_order_by [parameter::get_from_package_key -package_key intranet-freelance-translation -parameter FreelanceListSortOder -default "S-Word"]
    }
    set freel_trans_order_by [string tolower $freel_trans_order_by]

#    ad_return_complaint 1 $freel_trans_order_by

    # Sort order
    switch $freel_trans_order_by {
	s-word {
	    # Order by the number of time the freelance has worked before with the customer
	    set freel_trans_order_by_sql "f.no_times_worked_for_customer DESC"
	    set order_freelancer_sql "no_times_worked_for_customer DESC"
	}
	worked_before {
	    # Order by the number of time the freelance has worked before with the customer
	    set freel_trans_order_by_sql "f.no_times_worked_for_customer DESC"
	    set order_freelancer_sql "no_times_worked_for_customer DESC"
	}
	name {
	    set freel_trans_order_by_sql "f.name"
	    set order_freelancer_sql "user_name"
	}
	default {
	    set freel_trans_order_by_sql "min(p.price), p.source_language_id, p.target_language_id, p.task_type_id, p.subject_area_id, p.file_type_id"
	    set order_freelancer_sql "user_name"
	}

    }

    # ------------------------------------------------
    # Constants

    # Default Role: "Full Member"
    set default_role_id 1300
    
    # How many static columns?
    set colspan 3

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "

    set source_lang_skill_type 2000
    set target_lang_skill_type 2002

    set skill_type_sql "
	select	category_id as skill_type_id,
		category as skill_type
	from	im_categories
	where	(enabled_p = 't' OR enabled_p is NULL)
		and category_type = 'Intranet Skill Type'
	order by category_id
    "

    set skill_type_list [list]
    db_foreach skill_type $skill_type_sql {
	lappend skill_type_list $skill_type
	set skill_type_hash($skill_type) $skill_type_id
    }

    # Project's Source & Target Languages
    set project_source_lang [db_string source_lang "
                select  substr(im_category_from_id(source_language_id), 1, 2)
                from    im_projects
                where   project_id = :object_id" \
    -default 0]

    set project_target_langs [db_list target_langs "
		select '''' || substr(im_category_from_id(language_id), 1, 2) || '''' 
		from	im_target_languages 
		where	project_id = :object_id
    "]
    if {0 == [llength $project_target_langs]} { set project_target_langs [list "'none'"]}


    # ------------------------------------------------
    # Put together the main SQL

    set skill_type_sql ""
    foreach skill_type $skill_type_list {
	set skill_type_id $skill_type_hash($skill_type)
	append skill_type_sql "\t\tim_freelance_skill_list(u.user_id, $skill_type_id) as skill_$skill_type_id,\n"
    }

    set company_id [db_string source_lang "select company_id from im_projects where project_id=:object_id"]

    set freelance_sql "
	select distinct
		im_name_from_user_id(u.user_id) as user_name,
		im_name_from_user_id(u.user_id) as name,
		$skill_type_sql
		u.user_id,
		im_user_worked_for_company ( u.user_id, $company_id ) as no_times_worked_for_customer 
	from
		users u,
		group_member_map m, 
		membership_rels mr,
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
		m.group_id = acs__magic_object_id('registered_users'::character varying) AND 
		m.rel_id = mr.rel_id AND 
		m.container_id = m.group_id AND 
		m.rel_type::text = 'membership_rel'::text AND 
		mr.member_state::text = 'approved'::text AND 
		u.user_id = m.member_id AND
		sls.user_id = u.user_id AND
		tls.user_id = u.user_id
	order by
		$order_freelancer_sql
    "

    # ------------------------------------------------
    # Determine the price ranges per freelancer
    set price_sql "
	select
		f.user_id,
		c.company_id,
		p.uom_id,
		im_category_from_id(p.task_type_id) as task_type,
		im_category_from_id(p.source_language_id) as source_language,
		im_category_from_id(p.target_language_id) as target_language,
		im_category_from_id(p.subject_area_id) as subject_area,
		im_category_from_id(p.file_type_id) as file_type,
		min(p.price) as min_price,
		max(p.price) as max_price,
		f.no_times_worked_for_customer as no_times_worked_for_customer
	from
		($freelance_sql) f
		LEFT OUTER JOIN acs_rels uc_rel	ON (f.user_id = uc_rel.object_id_two)
		LEFT OUTER JOIN im_trans_prices p ON (uc_rel.object_id_one = p.company_id),
		im_companies c
	where
		p.company_id = c.company_id
	group by
		f.user_id,
		c.company_id,
		p.uom_id,
		p.task_type_id,
		p.source_language_id,
		p.target_language_id,
		p.subject_area_id,
		p.file_type_id,
		f.name,
		f.no_times_worked_for_customer
	order by 
		$freel_trans_order_by_sql 
    "

    db_foreach price_hash $price_sql {
	set key "$user_id-$uom_id"

	# Calculate the base cell value
	set price_append "$min_price - $max_price"
	if {$min_price == $max_price} { set price_append "$min_price" }

	# Add the list of parameters
	set param_list [list $price_append $source_language $target_language]
	if {"" == $source_language && "" == $target_language} { set param_list [list] }
	if {"" != $subject_area} { lappend param_list $subject_area }
	if {"" != $task_type} { lappend param_list $task_type }
	if {"" != $file_type} { lappend param_list $file_type }

	# Update the hash table cell
	set hash ""
	if {[info exists price_hash($key)]} { set hash $price_hash($key) }
	set hash [im_freelance_trans_member_select_component_join_prices $hash $param_list]
	set price_hash($key) $hash

	# deal with sorting the array be one of the 
	switch $freel_trans_order_by {
            "s-word" {
		if {$uom_id == 324} {
		    set sort_hash($user_id) [expr ($min_price + $max_price) / 2.0]
		}
	    }
            "hour" {
		if {$uom_id == 320} {
		    set sort_hash($user_id) [expr ($min_price + $max_price) / 2.0]
		}
	    }
            default { }
        }
    }

    foreach key [array names price_hash] {
	set values $price_hash($key)
	set result ""
	foreach value $values {
	    append result "<nobr>[lindex $value 0] {[lrange $value 1 end]}</nobr><br>\n"
	}
	set price_hash($key) $result
    }


    set uom_listlist [db_list_of_lists uom_list "
	select uom_id, im_category_from_id(uom_id)
	from (select distinct uom_id from ($price_sql) t) t
	order by uom_id
    "]


    # ------------------------------------------------
    # Check the times that every freelancer has worked with the current customer

    # Get the customer
    set customer_id [db_string source_lang "
                select	company_id
                from    im_projects
                where   project_id = :object_id
    " -default 0]

    set worked_with_customer_sql "
	select	f.user_id,
		ww.cnt
	from	($freelance_sql) f
		LEFT OUTER JOIN (
			select	count(*) as cnt,
				user_id
			from	(select	object_id_two as user_id,
					p.project_id
				from	acs_rels r,
					im_projects p
				where	p.company_id = :customer_id
					and r.object_id_one = p.project_id
				) ww
			group by
				user_id
		) ww ON ww.user_id = f.user_id
    "

    db_foreach worked_with_customer $worked_with_customer_sql {

	set cnt_pretty ""
	switch $cnt {
	     "" { set cnt_pretty [lang::message::lookup "" intranet-freelance-translation.never "never"] }
	     0 { set cnt_pretty [lang::message::lookup "" intranet-freelance-translation.never "never"] }
	     1 { set cnt_pretty [lang::message::lookup "" intranet-freelance-translation.once "once"] }
	     2 { set cnt_pretty [lang::message::lookup "" intranet-freelance-translation.twice "twice"] }
	     default { set cnt_pretty [lang::message::lookup "" intranet-freelance-translation.N_times "%cnt% times"] }
	}
	# Update the hash table cell
	set key "$user_id"
	set worked_with_hash($key) $cnt_pretty
    }

    # ------------------------------------------------
    # Mix Freelance Info with Prices

    set table_rows [list]
    db_foreach freelance $freelance_sql {

	# Set the default sort value to a random number, otherwise qsort will fail (below)
	set sort_val [expr 999999999 + 999999999 * rand()]
	if {[info exists sort_hash($user_id)]} { set sort_val $sort_hash($user_id) }

	set row [list $user_id $name $sort_val] 

	foreach skill_type $skill_type_list {
	    set skill_type_id $skill_type_hash($skill_type)
	    lappend row [expr "\$skill_$skill_type_id"]
	}
	lappend row $no_times_worked_for_customer
	lappend table_rows $row
    }

    set sorted_table_rows $table_rows
    if { ![info exists freel_trans_order_by] } {
	set sorted_table_rows [qsort $table_rows [lambda {s} { lindex $s 2 }]]
    } 
 

    # ------------------------------------------------

    # Remove "freel_trans_order_by" from the var_list
    set order_by_pos [lsearch $var_list "freel_trans_order_by"]
    if {$order_by_pos > -1} {
        set var_list [lreplace $var_list $order_by_pos $order_by_pos]
    } else {
        set var_list $var_list
    }

    # Format the table header
    set freelance_header_html "
	<tr class=rowtitle>
	  <td class=rowtitle>
	      <input type=checkbox name=_dummy onclick=\"acs_ListCheckAll('trans_freelancers',this.checked)\">
	  </td>
	  <td class=rowtitle><a href=[export_vars -base $current_url $var_list]&freel_trans_order_by=name>[_ intranet-freelance.Freelance]</a></td>
	  <!--<td class=rowtitle>[lang::message::lookup "" intranet-freelance-translation.Worked_with_Customer_Before "Worked With Cust Before?"]</td>-->
	  <td class=rowtitle><a href=[export_vars -base $current_url $var_list]&freel_trans_order_by=worked_before>[lang::message::lookup "" intranet-freelance-translation.Worked_with_Customer_Before "Worked With Cust Before?"]</a></td>
    "

    # Add a column for each skill type
    foreach skill_type $skill_type_list {
	regsub { } $skill_type "_" skill_type_mangled
	append freelance_header_html "
	    <td class=rowtitle>[lang::message::lookup "" intranet-freelance.$skill_type_mangled $skill_type]</td>
	"
	incr colspan
    }



    # Add a column for each UoM where there is a price per user.
    foreach uom_tuple $uom_listlist {
	set title [lindex $uom_tuple 1]
	set dir_select ""
	if {$freel_trans_order_by == [string tolower $title]} {
	    set dir_select "v"
	}
	append freelance_header_html "
		<td class=rowtitle>
		<a href=[export_vars -base $current_url $var_list]&freel_trans_order_by=$title>$title</a>
		$dir_select
		</td>
	"
	incr colspan
    }
    append freelance_header_html "</tr>"

    # ------------------------------------------------
    # Format the table body

    set ctr 0
    set freelance_body_html ""
    foreach freelance_row $sorted_table_rows {

        set user_id [lindex $freelance_row 0]
	set name [lindex $freelance_row 1]
	
	append freelance_body_html "
	<tr$bgcolor([expr $ctr % 2])>\n"

	append freelance_body_html "<td><input type=checkbox name=user_id_from_search id=trans_freelancers,$user_id value=$user_id></td>"

	set worked_with_cust [lindex $freelance_row 10]
	set worked_with_cust ""
	set key "$user_id"
	if {[info exists worked_with_hash($key)]} { set worked_with_cust $worked_with_hash($key) }
	
	append freelance_body_html "
	  <td><a href=users/view?[export_url_vars user_id]><nobr>$name</nobr></a></td>
	  <td>$worked_with_cust</td>
        "

	# Add a column for each skill type
	set col_cnt 3
	foreach skill_type $skill_type_list {
	    append freelance_body_html "
                <td>[lindex $freelance_row $col_cnt]</td>
            "
	    incr col_cnt
	}

	foreach uom_tuple $uom_listlist {
	    set uom_id [lindex $uom_tuple 0]
	    set key "$user_id-$uom_id"
	    set val ""
	    if {[info exists price_hash($key)]} { set val $price_hash($key) }
	    append freelance_body_html "<td>$val</td>\n"
	}
	append freelance_body_html "</tr>"
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
	</form>
    "
    
    return $select_freelance
}

