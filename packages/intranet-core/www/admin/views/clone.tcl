# 
#
# Copyright (c) 2013, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
 
ad_page_contract {
    
    Clone a view
    
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2013-02-10
    @cvs-id $Id$
} {
    old_view_id:integer
    {return_url ""}
} -properties {
} -validate {
} -errors {
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}
set page_title "[_ intranet-core.Clone_View]"
set context $page_title
set current_url $return_url
if {"" == $return_url} { set return_url [im_url_with_query] }
set focus "view.view_name"

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


ad_form \
    -name view \
    -cancel_url $return_url \
    -export {return_url old_view_id} \
    -form {
	new_view_id:key(im_views_seq)
	{view_name:text(text) {label #intranet-core.View_Name#} }
	{view_label:text(text) {label #intranet-core.View_Label#} }
	{view_type_id:text(im_category_tree),optional {label #intranet-core.View_Type#} {custom {category_type "Intranet DynView Type"}} {value ""} }
	{view_status_id:text(im_category_tree),optional {label #intranet-core.View_Status#} {custom {category_type "Intranet DynView Status"}} {value ""} }
	{sort_order:integer(text),optional {label #intranet-core.Sort_Order#} {html {size 10 maxlength 15}}}
	{view_sql:text(textarea),optional {label #intranet-core.View_sql#} {html {cols 50 rows 5}}}
    }


ad_form -extend -name view -on_request {
    # Populate elements from local variables
    
    db_1row populate "select	v.*
	from	im_views v
	where	v.view_id = :old_view_id"


} -select_query {


} -validate {

        {view_name
            {![db_string unique_name_check "
		select count(*)
		from im_views 
		where
			view_name = :view_name 
			and view_id != :new_view_id"]
	    }
            "Duplicate View Name. Please use a new name."
        }

} -new_data {
    
    set max_column_id [db_string column_id "select max(column_id) from im_view_columns" -default 100000]
    set column_id $max_column_id

    db_dml view_insert "
    insert into IM_VIEWS
    (view_id, view_name, view_status_id, view_type_id, sort_order, view_sql, view_label)
    values
    (:new_view_id, :view_name, :view_status_id, :view_type_id, :sort_order, :view_sql, :view_label)
    "
    

    db_foreach column {
	select group_id, column_name, column_render_tcl, extra_select, extra_from,
	extra_where, sort_order, order_by_clause, visible_for, ajax_configuration, variable_name, datatype
	from im_view_columns where view_id = :old_view_id
    } {
	incr column_id
	
	db_dml column_insert {
	    insert into im_view_columns
	    (column_id, view_id,group_id, column_name, column_render_tcl, extra_select, extra_from,extra_where, sort_order, order_by_clause, visible_for, ajax_configuration, variable_name, datatype)
	    values
	    (:column_id, :new_view_id,:group_id, :column_name, :column_render_tcl, :extra_select, :extra_from, :extra_where, :sort_order, :order_by_clause, :visible_for, :ajax_configuration, :variable_name, :datatype)
	}   

    }

} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

        # Flush permissions
        im_permission_flush

	# Redirect
	ad_returnredirect [export_vars -base "/intranet/admin/views/new" -url {{view_id $new_view_id}}]
	ad_script_abort
}

