# /packages/intranet-sysconfig/www/export-conf/index.tcl
#
# Copyright (c) 20012 ]project-open[
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
    Export the current configuration to a CSV file
    @author frank.bergmann@project-open.com
} {
    { format "html" }
    { report_name "export-conf" }
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]"
    return
}

set page_title [lang::message::lookup "" intranet-sysconfig.Export_Conf "Export Configuration"]
set context_bar [im_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

set subsite_name ""


set base_sql "
	select	'category' as type,
		c.category_type || '.' || c.category as key,
		'intranet-core' as package_key,
		c.enabled_p as value
	from	im_categories c
	UNION
	select	'portlet' as type,
		p.plugin_name as key,
		p.package_name as package_key,
		p.enabled_p as value
	from	im_component_plugins p
	UNION
	select	'menu' as type,
		m.label as key,
		m.package_name as package_key,
		m.enabled_p as value
	from	im_menus m
	UNION
	select	o.object_type as type,
		o.object_type || '.' || acs_object__name(p.object_id) as key,
		'intranet-core' as package_key,
		im_sysconfig_display_permissions(p.object_id) as value
	from	(select distinct object_id from acs_permissions) p,
		acs_objects o
	where	p.object_id = o.object_id and
		o.object_type in (
			'im_menu', 'im_component_plugin', 'im_profile', 
			'im_rest_object_type', 'im_cost_center', 'im_dynfield_attribute'
		)
	UNION
	select distinct
		'privilege' as type,
		ap.privilege as key,
		'intranet-core' as package_key,
		im_sysconfig_display_privileges(ap.privilege) as value
	from	acs_permissions ap
	where	ap.object_id in (
			select min(object_id) from acs_objects 
			where object_type = 'apm_service'
		)
	UNION
	select	'parameter' as type,
		p.parameter_name as key,
		p.package_key,
		pv.attr_value as value
	from	apm_parameters p,
		apm_parameter_values pv
	where	p.parameter_id = pv.parameter_id
"

set sql "
	select	package_key,
		type,
		key,
		value
	from	($base_sql) b
	order by
		package_key,
		type,
		key
"

set page_body [im_ad_hoc_query \
	-format $format \
	-translate_p 0 \
	$sql \
]


# ---------------------------------------------------------------
# Return the right HTTP response, depending on $format
#
switch $format {
    "csv" {
	# Return file with ouput header set
	set report_key [string tolower $report_name]
	regsub -all {[^a-zA-z0-9_]} $report_key "_" report_key
	regsub -all {_+} $report_key "_" report_key
	set outputheaders [ns_conn outputheaders]
	ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${report_key}.csv"
	doc_return 200 "application/csv" $page_body
	ad_script_abort
    }
    "xml" {
	# Return plain file
	doc_return 200 "application/xml" $page_body
	ad_script_abort
    }
    "json" {
	set result "{\"success\": true,\n\"message\": \"Data loaded\",\n\"data\": \[$page_body\n\]\n}"
	doc_return 200 "text/plain" $result
	ad_script_abort
    }
    "plain" {
	ad_return_complaint 1 "Not Defined Yet"
    }
    default {
	# just continue with the page to format output using template
    }
}

