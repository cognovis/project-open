# /packages/intranet-core/www/users/nuke.tcl
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
    Try to remove a user completely

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    conf_item_id:integer,notnull
    { return_url "/intranet-confdb/index" }
}


db_1row ci_info "
	select	*
	from	im_conf_items
	where	conf_item_id = :conf_item_id
"

set page_title [lang::message::lookup "" intranet-confdb.Nuke_this_conf_item "Nuke Conf Item '%conf_item_name%'"]
set context_bar [im_context_bar [list "/intranet-confdb/index"] $page_title]
set object_name $conf_item_name
set object_type "im_conf_item"
set object_url [export_vars -base "/intranet-confdb/new" {{form_mode display} conf_item_id}]

