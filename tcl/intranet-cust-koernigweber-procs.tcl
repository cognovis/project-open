# /packages/intranet-cust-koernigweber/tcl/intranet-cust-koernigweber-procs.tcl
#
# Copyright (C) 1998-2011 


ad_library {
    
    Customizations implementation KoernigWeber 
    @author klaus.hofeditz@project-open.com
}

# ---------------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# ---------------------------------------------------------------------

ad_proc -public im_group_member_component_employee_customer_price_list { 
    {-debug 0}
    object_id 
    current_user_id 
    { add_admin_links 0 } 
    { return_url "" } 
    { limit_to_users_in_group_id "" } 
    { dont_allow_users_in_group_id "" } 
    { also_add_to_group_id "" } 
} {
    Returns an html formatted list of all the users in the specified
    group. 

    Required Arguments:
    -------------------
    - object_id: Group we're interested in.
    - current_user_id: The user_id of the person viewing the page that
      called this function. 

    Optional Arguments:
    -------------------
    - description: A description of the group. We use pass this to the
      spam function for UI
    - add_admin_links: Boolean. If 1, we add links to add/email
      people. Current user must be member of the specified object_id to add
      him/herself
    - return_url: Where to go after we do something like add a user
    - limit_to_users_in_group_id: Only shows users who belong to
      group_id and who are also members of the group specified in
      limit_to_users_in_group_id. For example, if object_id is an intranet
      project, and limit_to_users_group_id is the object_id of the employees
      group, we only display users who are members of both the employees and
      this project groups
    - dont_allow_users_in_group_id: Similar to
      limit_to_users_in_group_id, but says that if a user belongs to the
      object_id specified by dont_allow_users_in_group_id, then don't display
      that user.  
    - also_add_to_group_id: If we're adding users to a group, we might
      also want to add them to another group at the same time. If you set
      also _add_to_group_id to a object_id, the user will be added first to
      object_id, then to also_add_to_group_id. Note that adding the person to
      both groups is NOT atomic.

    Notes:
    -------------------
    This function has quickly become complicated. Any proposals to simplify
    are welcome...

} {
    # Check if there is a percentage column from intranet-ganttproject
    set show_percentage_p [im_column_exists im_biz_object_members percentage]
    set object_type [util_memoize "db_string otype \"select object_type from acs_objects where object_id=$object_id\" -default \"\""]
    if {$object_type != "im_project" & $object_type != "im_timesheet_task"} { set show_percentage_p 0 }

    # ------------------ limit_to_users_in_group_id ---------------------
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "
	and exists (select 1 
		from 
			group_member_map map2,
		        membership_rels mr,
			groups ug
		where 
			map2.group_id = ug.group_id
			and map2.rel_id = mr.rel_id
			and mr.member_state = 'approved'
			and map2.member_id = u.user_id 
			and map2.group_id = :limit_to_users_in_group_id
		)
	"
    } 

    # ------------------ dont_allow_users_in_group_id ---------------------
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "
	and not exists (
		select 1 
		from 
			group_member_map map2, 
			membership_rels mr,
			groups ug
		where 
			map2.group_id = ug.group_id
			and map2.rel_id = mr.rel_id
			and mr.member_state = 'approved'
			and map2.member_id = u.user_id 
			and map2.group_id = :dont_allow_users_in_group_id
		)
	"
    } 

    set bo_rels_percentage_sql ""
    if {$show_percentage_p} {
	set bo_rels_percentage_sql ",round(bo_rels.percentage) as percentage"
    }

    # ------------------ Main SQL ----------------------------------------
    # fraber: Abolished the "distinct" because the role assignment page 
    # now takes care that a user is assigned only once to a group.
    # We neeed this if we want to show the role of the user.
    #
    set sql_query "
	select
		u.user_id, 
		u.user_id as party_id,
		pl.*,
		im_email_from_user_id(u.user_id) as email,
		im_name_from_user_id(u.user_id) as name,
		im_category_from_id(c.category_id) as member_role,
		c.category_gif as role_gif,
		c.category_description as role_description
		$bo_rels_percentage_sql
	from
		users u,
		acs_rels rels
		LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
		LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id),
		group_member_map m,
		membership_rels mr,
		im_employee_customer_price_list pl
	where
		rels.object_id_one = $object_id
		and rels.object_id_two = u.user_id
		and mr.member_state = 'approved'
		and u.user_id = m.member_id
		and mr.member_state = 'approved'
		and m.group_id = acs__magic_object_id('registered_users'::character varying)
		and m.rel_id = mr.rel_id
		and m.container_id = m.group_id
		and m.rel_type = 'membership_rel'
		and pl.company_id = $object_id
		$limit_to_group_id_sql 
		$dont_allow_sql
	order by lower(im_name_from_user_id(u.user_id))
    "

    # ------------------ Format the table header ------------------------
    set colspan 1
    set header_html "
      <tr> 
	<td class=rowtitle align=middle>[_ intranet-core.Name]</td>
    "
    if {$show_percentage_p} {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[_ intranet-core.Perc]</td>"
    }
    if {$add_admin_links} {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[im_gif delete]</td>"
    }
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""
    db_foreach users_in_group $sql_query {

	# Make up a GIF with ALT text to explain the role (Member, Key 
	# Account, ...
	set descr $role_description
	if {"" == $descr} { set descr $member_role }
	set descr_tr [lang::util::suggest_key $descr]
	set profile_gif [im_gif $role_gif $descr_tr]

	incr count
	if { $current_user_id == $user_id } { set found 1 }

	# determine how to show the user: 
	# -1: Show name only, 0: don't show, 1:Show link
	set show_user [im_show_user_style $user_id $current_user_id $object_id]
	if {$debug} { ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user" }

	if {$show_user == 0} { continue }

	append body_html "
<tr $td_class([expr $count % 2])>
  <input type=hidden name=member_id value=$user_id>
  <td>"
	if {$show_user > 0} {
append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name</A>"
	} else {
append body_html $name
	}

	append body_html "$profile_gif</td>"
	if {$show_percentage_p} {
	    append body_html "
		  <td align=middle>
		    <input type=input size=4 maxlength=4 name=\"percentage.$user_id\" value=\"$percentage\">
		  </td>
	    "
	}

        append body_html "$profile_gif</td>"
        if {$show_percentage_p} {
            append body_html "
                  <td align=middle>
                    <input type=input size=4 maxlength=4 name=\"amount.$user_id\" value=\"$amount\">
                  </td>
            "
        }

	if {$add_admin_links} {
	    append body_html "
		  <td align=middle>
		    <input type=checkbox name=delete_user value=$user_id>
		  </td>
	    "
	}
	append body_html "</tr>"
    }

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>[_ intranet-core.none]</i></td></tr>\n"
    }

    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
    if {$add_admin_links} {

	set spam_members_html ""
	if {[im_table_exists spam_messages]} {
	    set spam_members_html "<li><A HREF=\"[spam_base]spam-add?[export_url_vars object_id sql_query]\">[_ intranet-core.Spam_Members]</A>&nbsp;"
	    set spam_members_html "<option value=spam_members>[_ intranet-core.Spam_Members]</option>\n"
	}


	append footer_html "
	    <tr>
	      <td align=left>
		<ul>
		<li><A HREF=\"/intranet/member-add?[export_url_vars object_id also_add_to_group_id return_url]\">[_ intranet-core.Add_member]</A>
		</ul>
	      </td>
	"

	append footer_html "
	    <tr>
	      <td align=right colspan=$colspan>
		<select name=action>
	"
#		<option value=add_member>[_ intranet-core.Add_a_new_member]</option>


	if {$show_percentage_p} {
	    append footer_html "
		<option value=update_members>[_ intranet-core.Update_members]</option>
	    "
	}
	append footer_html "
		<option value=del_members>[_ intranet-core.Delete_members]</option>
		$spam_members_html
		</select>
		<input type=submit value='[_ intranet-core.Apply]' name=submit_apply></td>
	      </td>
	    </tr>
	"
    }

    # ------------------ Join table header, body and footer ----------------
    set html "
	<form method=POST action=/intranet/member-update>
	[export_form_vars object_id return_url]
	    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
	      $header_html
	      $body_html
	      $footer_html
	    </table>
	</form>
    "
    return $html
}



ad_proc -public im_employee_customer_price_list_new {

    user_id:integer,notnull
    company_id:integer,notnull
    user_id:integer,notnull
    amount
    currency 

} {
        select im_employee_customer_price__new (
                null, ''im_employee_customer_price'', now()::date,
                [ad_conn user_id], ''0.0.0.0'', 0,
                user_id,
		company_id,
		amount,
		currency 
		) into id;
    	return id; 
}

