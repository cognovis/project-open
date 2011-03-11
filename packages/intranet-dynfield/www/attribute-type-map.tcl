ad_page_contract {
    Show an Attribute - Object (Sub-) Type table.
    This table allows admins to determine where DynField attributes
    should appear, depending on the object's ]po[-type_id
    (as opposed to the OpenACS type)

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @cvs-id $Id: attribute-type-map.tcl,v 1.12 2011/03/03 12:55:30 po34demo Exp $
} {
    object_type:optional
    nomaster_p:optional
    attribute_id:optional
    { object_subtype_id 0 }
}

# --------------------------------------------------------------

set page_title "Attribute-Type-Map"
set context [list [list "index" "DynFields"] $page_title]

if {![info exists nomaster_p]} { set nomaster_p 0 }
if {![info exists object_type]} { set object_type "" }
if {[info exists attribute_id] && "" != $attribute_id} {
    set object_type [db_string otype "
	select	object_type
	from	acs_attributes
	where	attribute_id in (
			select	acs_attribute_id
			from	im_dynfield_attributes
			where	attribute_id = :attribute_id
		)
    " -default ""]
}


set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set return_url [im_url_with_query]
set acs_object_type $object_type

# --------------------------------------------------------------
# Horizontal Dimension - Just the list of ObjectTypes
# The mapping between object types and categories is
# not dealt with in acs_object_types, so hard-code here
# while we haven't integrated this into the Metadata model.
# ToDo: Integrate type and status into metadata model.

set category_type [im_dynfield::type_category_for_object_type -object_type $acs_object_type]
if {"" == $category_type} { 
    ad_return_complaint 1 "
	No 'Type Category Type' defined for type '$object_type'<br>
	The field 'acs_object_types.type_category_type' is empty for object type '$object_type'.<br>
	This probably means that the SQL creation or upgrade scripts have not run for this object type.
    "
}


set object_subtype_sql ""
if {"" != $object_subtype_id && 0 != $object_subtype_id} {
    set object_subtype_sql "and category_id in ([join [im_sub_categories $object_subtype_id] ","])"
}

# The "dimension" is a list of values to be displayed on top.
set top_scale [db_list top_dim "
	select	category_id
	from	im_categories
	where	category_type = :category_type and
		(enabled_p is null or enabled_p = 't')
		$object_subtype_sql
	order by
		category_id
"]

# The array maps category_id into "category" - a pretty 
# string for each column, to be used as column header
set max_length 8
db_foreach top_scale_map "
	select	category_id,
		category
	from	im_categories
	where	category_type = :category_type
		$object_subtype_sql
	order by
		category_id
" { 
    set col_title ""
    foreach c $category {
	if {[string length $c] == [expr $max_length+1]} { 
	    append col_title $c
            set c ""
	}
	while {[string length $c] > $max_length} {
	    append col_title "[string range $c 0 [expr $max_length-1]] "
	    set c [string range $c $max_length end]
	}
	append col_title " $c "
    }
    set top_scale_map($category_id) $col_title
}


# --------------------------------------------------------------
# Vertical Dimension - The list of DynField Attributes
# The "dimension" is a list of values to be displayed on left.

set attribute_where ""
if {[info exists attribute_id] && "" != $attribute_id && 0 != $attribute_id} { set attribute_where "and a.attribute_id = :attribute_id" }

set left_scale [db_list left_dim "
        select  a.attribute_id
        from
                im_dynfield_attributes a,
                acs_attributes aa,
                im_dynfield_layout idl
        where
                a.acs_attribute_id = aa.attribute_id
                and aa.object_type = :acs_object_type
                and idl.attribute_id = a.attribute_id
		$attribute_where
        order by
                aa.sort_order, idl.pos_y, aa.pretty_name
"]

# The array maps category_id into "attribute_id category" - a pretty
# string for each column, to be used as column header
db_foreach left_scale_map "
	select	a.attribute_id,
		aa.pretty_name
	from
		im_dynfield_attributes a,
		acs_attributes aa
	where
		a.acs_attribute_id = aa.attribute_id
		and aa.object_type = :acs_object_type
	order by
		aa.sort_order, aa.pretty_name
" { set left_scale_map($attribute_id) $pretty_name }



# --------------------------------------------------------------
# Get the information about the map and stuff it into a hash array
# for convenient matrix display.
set sql "
	select  m.attribute_id,
	        m.object_type_id,
	        m.display_mode
	from
	        im_dynfield_type_attribute_map m,
	        im_dynfield_attributes a,
	        acs_attributes aa
	where
	        m.attribute_id = a.attribute_id
	        and a.acs_attribute_id = aa.attribute_id
	        and aa.object_type = :acs_object_type
	order by
		aa.sort_order, aa.pretty_name
"
db_foreach attribute_table_map $sql {
    set key "$attribute_id.$object_type_id"
    set hash($key) $display_mode
    ns_log Notice "attribute-type-map: hash($key) <= $display_mode"
}



# --------------------------------------------------------------
# Display the table

set header "<td></td>\n"
foreach top $top_scale {
    set top_pretty $top_scale_map($top)
    append header "
	<td class=rowtitle>
	$top_pretty
	</td>
    "
}
set header_html "<tr class=rowtitle valign=top>\n$header</tr>\n"

set url "attribute-type-map-toggle.tcl"
set body_html ""
set ctr 0
foreach left $left_scale {
    set attribute_id $left
    append body_html "<tr $bgcolor([expr $ctr % 2])>\n"
    append body_html "<td>$left_scale_map($left)</td>\n"

    foreach top $top_scale {
	set object_type_id $top
	set key "$attribute_id.$object_type_id"
	set mode "none"
	if {[info exists hash($key)]} { set mode $hash($key) }
	ns_log Notice "attribute-type-map: hash($key) => $mode"

	set none_checked ""
	set disp_checked ""
	set edit_checked ""
	switch $mode {
	    none { set none_checked "checked" }
	    display { set disp_checked "checked" }
	    edit { set edit_checked "checked" }
	}

	set val "
<nobr>
<font size=-2>
<input value=none type=radio name=\"attrib.$attribute_id.$object_type_id\" $none_checked>
<input value=display type=radio name=\"attrib.$attribute_id.$object_type_id\" $disp_checked>
<input value=edit type=radio name=\"attrib.$attribute_id.$object_type_id\" $edit_checked>
</font>
</nobr>
"

	append body_html "<td>$val</td>\n"
    }
    append body_html "</tr>\n"
    incr ctr
}

