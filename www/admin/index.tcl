# /packages/intranet-core/www/admin/categories/index.tcl
#
# Copyright (C) 2004 ]project-open[
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
  Home page for category administration.

  @author guillermo.belcic@project-open.com
  @author frank.bergmann@project-open.com
} {
    { select_category_type "All" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set core_package_version_sql "
      select  version_name
      from    apm_package_versions
      where   package_key = 'intranet-core' and
              enabled_p = 't'
"
set core_version [db_string core_version $core_package_version_sql -default ""]

set page_title "[_ intranet-core.Administration] &\#93;project-open&\#91; $core_version"
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# Check for upgrades to run

set core_package_version_sql "
      select  version_name
      from    apm_package_versions
      where   package_key = 'intranet-core' and
              enabled_p = 't'
"
set core_version [db_string core_version $core_package_version_sql -default ""]

set upgrade_message "<b>You are running core version: $core_version </b><br><br>"
append upgrade_message [im_check_for_update_scripts]


# ---------------------------------------------------------
# Adminstration Area with GIFs
# ---------------------------------------------------------

set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label = 'admin'" -default 0]]
set menu_sql "
	select	m.*
	from	im_menus m
	where	m.parent_menu_id = :parent_menu_id
	order by
		m.sort_order
"

set menu_gif_large ""
set menu_gif_medium ""
set menu_gif_small ""
set menu_html ""
db_foreach admin_menu $menu_sql {
    set menu_gif ""
    if {"" == $menu_gif} { set menu_gif $menu_gif_large }
    if {"" == $menu_gif} { set menu_gif $menu_gif_medium }
    if {"" == $menu_gif} { set menu_gif $menu_gif_small }
    if {"" == $menu_gif} { set menu_gif "plus" }

    append menu_html "<div class='admin_menu_item'>[im_gif $menu_gif] <a href=\"$url\">$name</a></div>\n"
}

set menu_html "
<div class='admin_menu_block'>
$menu_html
</div>
"