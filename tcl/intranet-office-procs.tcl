# /packages/intranet-core/tcl/intranet-office-procs.tcl
#
# Copyright (C) 2004 Project/Open
# The code is based on work from ArsDigita ACS 3.4 and OpenACS 5.0
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {

    Procedures related to offices

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
}

# -----------------------------------------------------------
# Office OO methods new, del and name
# -----------------------------------------------------------


ad_proc -public im_office_permissions {user_id office_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $office_id.<BR>
    The permissions depend on whether the office is a customers office or
    an internal office:
    <ul>
      <li>Internal Offices:<br>
	  Are readable by all employees
      <li>Customer Offices:<br>
	  Need either global customer access permissions
	  or the be the Key account of the respective customer.
    </ul>
    Write and administration rights are only for administrators
    and the customer key account managers.

} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 1
    set read 0
    set write 0
    set admin 0

    # Check if the customer is "internal"
    set customer_type [db_1row customer_type "
select
	im_category_from_id(c.customer_type_id) as customer_type,
	c.customer_id
from
	im_offices o,
	im_customers c
where
	o.office_id = :office_id
	and o.customer_id = c.customer_id(+)
"]

    ns_log Notice "im_office_permission: customer_type=$customer_type"

    # Now there are three options:
    # NULL: not assigned to any customer yet
    # 'internal': An internal office and
    # != 'internal': A customers office

    # Internal office: Allow employees to see the offices and
    # Senior Managers to change them (or similar, as defined
    # in the permission module)
    if {[string equal "internal" $customer_type]} {
	set admin [im_permission $user_id edit_internal_offices]
	set read [im_permission $user_id view_internal_offices]

	if {$user_is_office_admin_p} { set admin 1 }
	if {$user_is_office_member_p} { set read 1}

	if {$admin} { set read 1}
	set write $admin
	return
    }
    
    # The office if a customers office or a "dangeling" office
    # (office without a customer)
    set user_is_customer_member_p [im_biz_object_member_p $user_id $customer_id]
    set user_is_customer_admin_p [im_biz_object_admin_p $user_id $customer_id]

    set read [expr $user_is_customer_member_p || [im_permission $user_id view_customer_contacts]]
    set admin $user_is_customer_admin_p
    set write $admin

    if {$admin} { set read 1 }
}


namespace eval office {

    ad_proc -public new {
	{ -office_name "" }
	{ -office_path "" }
	{ -office_type_id "" }
	{ -office_status_id "" }
	{ -office_id "" } 
	{ -creation_date "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -context_id "" } 
    } {
	Creates a new office object. Offices can be either of "Internal"
	customer (-> Internal offices) or of regular customers.
	This difference determines the access permissions, because internal
	offices should be seen by all employees, while customer offices
	are more sensitive data.

	@author frank.bergmann@project-open.com

	@return <code>office_id</code> of the newly created office

	@param office_name Pretty name for the office
	@param office_path Path for office files in the filestorage
	@param office_type_id Configurable office type used for reporting 
	@param office_status_id Default: "Active": Allows to follow-
	       up through the office acquistion process
	@param others The default optional parameters for OpenACS
	       objects    
    } {

	# -----------------------------------------------------------
	# Check for duplicated unique fields (name & path)
	# We asume the application page knows how to deal with
	# the uniqueness constraint, so we won't generate an error
	# but just return the duplicated item. 
	set office_id 0
	set dup_sql "
select	office_id 
from	im_offices 
where	office_name = :office_name 
	or office_path = :office_path"
	db_foreach dup_offices $dup_sql {  
	    # nope - sets office_id 
	}
	if {0 != $office_id} { 
	    ns_log Notice "office::new: found existing office with same name: $office_id"
	    return $office_id 
	}

	# -----------------------------------------------------------
	set sql "
    begin
	:1 := im_office.new(
        object_type     => 'im_office'
        , office_name     => '$office_name'
        , office_path     => '$office_path'
"
	if {"" != $creation_date} { append sql "\t, creation_date => '$creation_date'\n" }
	if {"" != $creation_user} { append sql "\t, creation_user => '$creation_user'\n" }
	if {"" != $creation_ip} { append sql "\t, creation_ip => '$creation_ip'\n" }
	if {"" != $context_id} { append sql "\t, context_id => $context_id\n" }
	if {"" != $office_type_id} { append sql "\t, office_type_id => $office_type_id\n" }
	if {"" != $office_status_id} { append sql "\t, office_status_id => $office_status_id\n" }
	append sql "        );
    end;
"
	set office_id [db_exec_plsql create_new_office $sql]
	return $office_id
    }

}


# ----------------------------------------------------------------------
# Office HTML Components
# ---------------------------------------------------------------------

ad_proc -public im_office_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the office_types in the system
} {
    return [im_category_select "Intranet Office Type" $select_name $default]
}

ad_proc -public im_office_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the office_types in the system
} {
    return [im_category_select "Intranet Office Status" $select_name $default]
}


ad_proc -public im_office_component { user_id customer_id } {
    Creates a HTML table showing the table of offices related to the
    specified customer.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"
    set office_view_page "/intranet/offices/view"

    set sql "
select
	o.*,
	im_category_from_id(o.office_type_id) as office_type
from
	im_offices o
where
	o.customer_id = :customer_id
"

    set component_html "
<table cellspacing=1 cellpadding=1>
<tr class=rowtitle>
  <td class=rowtitle>Office</td>
  <td class=rowtitle>Type</td>
</tr>\n"

    set ctr 1
    db_foreach office_list $sql {
	append component_html "
<tr$bgcolor([expr $ctr % 2])>
  <td>
    <A href=\"$office_view_page?office_id=$office_id\">$office_name</A>
  </td>
  <td>
    $office_type
  </td>
</tr>\n"
	incr ctr
    }
    append component_html "</table>\n"

    return $component_html
}


