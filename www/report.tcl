ad_page_contract {
	testing reports	
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Backup"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "<li>You have insufficient privileges to see this page"
    return
}


# ------------------------------------------------------------
# Return the page header.
#

ad_return_top_of_page "[im_header]\n[im_navbar]"
ns_write "<H1>$page_title</H1>\n"

set joined_ids [join [array names view] ","]

set sql "
select
	v.*
from 
	im_views v
where 
	v.view_id in ($joined_ids)
"

    # Get the Backup SQL
    #
    set rows [db_0or1row get_backup_info "
select
	view_sql as backup_sql,
	view_name
from
	im_views
where
	view_id = 1004
"]


	#init counters
	set total_month_0409 ""
	set total_month_0410 ""
	set total_month_0411 ""
	set total_month_0504 ""
	set total_month_0505 ""
	set total_month_0506 ""
	
	# Get counters
	set counters(month_0409) {set total_month_0409 [expr $total_month_0409 + $month_0409]}  
	set counters(month_0410) {set total_month_0410 [expr $total_month_0410 + $month_0410]}
	set counters(month_0411) {set total_month_0411 [expr $total_month_0411 + $month_0411]}  
	set counters(month_0504) {set total_month_0504 [expr $total_month_0504 + $month_0504]}  
	set counters(month_0505) {set total_month_0505 [expr $total_month_0505 + $month_0505]}  
	set counters(month_0506) {set total_month_0506 [expr $total_month_0506 + $month_0506]} 
	set counter_list [array names counters]
	set counter_group due_month

    # Define the column headers and column contents that
    # we want to show:
    #
    set column_sql "
select
	column_name,
	column_render_tcl,
	visible_for
from
	im_view_columns
where
	view_id=1004
	and group_id is null
order by
	sort_order"

    set column_headers [list]
    set column_vars [list]
    set header ""
    set row_ctr 0
    db_foreach column_list_sql $column_sql {
		lappend column_headers "$column_name"
		lappend column_vars "$column_name"

		append header "<th>$column_name</th>"
		incr row_ctr
    }

# Execute the query
#
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set results ""
db_foreach projects_info_query $backup_sql {

		if { [info exists old_group_value] } {
			set group_value [set $counter_group]
			ns_log WARNING "$old_group_value != $group_value"
					
			if { $old_group_value != $group_value } {
				append results "<tr>$sub_total_row</tr>\n"
			}		
		}
		

		# Append a line of data based on the "column_vars" parameter list
		set row_ctr 0
		append results "<tr$bgcolor([expr $ctr % 2])>\n"
		set sub_total_row ""
		foreach column_var $column_vars {
			append results "\t<td valign=top>"
			set cmd "append results [set $column_var]"
			eval $cmd
			
			incr row_ctr
			set next_row ""
			
			# check counters
			if { [lsearch -exact $counter_list $column_var] != "-1" } {
				set cmd $counters($column_var)
				eval $cmd
				set total_value [set total_$column_var]			
				if { [info exists old_group_value] } {
					set group_value [set $counter_group]
					if { $old_group_value != $group_value } {
						#reset total
						set total_$column_var ""
					}		
				}

				append sub_total_row "<td>subtotal $column_var: $total_value</td>"
			} else {
				append sub_total_row "<td>&nbsp;</td>"
			}
			append results "</td>\n"
		
		}


		#store row for counter reset and print
	    set old_group_value [set $counter_group]
	    
	    append results "</tr>\n"
		incr ctr
}

#add last subtotal
set group_value [set $counter_group]
ns_log WARNING "$old_group_value != $group_value"
append results "<tr>$sub_total_row</tr>\n"


ns_write "<table><tr>$header</tr> $results </table>"


ns_write "
Successfully finished
<pre>$backup_sql


$total_month_0409
$total_month_0410
$total_month_0411
$total_month_0504
$total_month_0505
$total_month_0506
</pre>
"

ns_write [im_footer]


