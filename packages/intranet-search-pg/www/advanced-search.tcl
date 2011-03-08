# packages/intranet-search-pg/www/advanced-search.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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

ad_page_contract {
    @author Neophytos Demetriou
    @author Frank Bergmann
} {
    {q ""}
    {num 0}
}

set package_id [ad_conn package_id]

if { $num == 0 } {
    set num [ad_parameter -package_id $package_id LimitDefault]
}

set page_title [lang::message::lookup "" intranet-search-pg.Advanced_Search "Advanced Search"]


set sql "
	select
		sot.object_type_id,
		aot.object_type,
		aot.pretty_name as object_type_pretty_name,
		aot.pretty_plural as object_type_pretty_plural
	from
		im_search_object_types sot,
		acs_object_types aot
	where
		sot.object_type = aot.object_type
"

set objects_html ""
db_foreach object_type $sql {

    regsub -all { } $object_type_pretty_name {_} object_type_pretty_name_sub
    set object_type_pretty_name [lang::message::lookup "" intranet-core.$object_type_pretty_name_sub $object_type_pretty_name]
    append objects_html "
	<tr>
	  <td>
	    <input type=checkbox name=type value='$object_type' checked>
	  </td>
	  <td>
	    $object_type_pretty_name
	  </td>
	</tr>
"
}

ad_return_template