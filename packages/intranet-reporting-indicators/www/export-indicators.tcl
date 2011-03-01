# /packages/intranet-reporting-indicators/www/export-indicators.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved
#

ad_page_contract {
    Export the indicators so that they can be imported into a different system.

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {!$user_admin_p} {
    ad_return_complaint 1 "You don't have permissions to see this page"
    ad_script_abort
}

if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""



set indicator_sql "
	select
		r.*,
		i.*
	from
		im_reports r,
		im_indicators i
	where
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator]
"

db_foreach indicators $indicator_sql {

    # Quote the text strings for SQL
    regsub -all {'} $report_sql "''''" report_sql
    regsub -all {'} $report_name "''''" report_name
    regsub -all {'} $report_description "''''" report_description

    # Set specific NULL, otherwise we get a syntax error
    if {"" == $indicator_section_id} { set indicator_section_id "NULL" }

    append ddl "
create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''$report_name'',
		''$report_code'',
		$report_type_id,
		$report_status_id,
		''$report_sql'',
		$indicator_widget_min,
		$indicator_widget_max,
		$indicator_widget_bins
	);

	update im_indicators set
		indicator_section_id = $indicator_section_id
	where indicator_id = v_id;

	update im_reports set
		report_description = ''$report_description''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    \n"
}

doc_return 200 "text/html" "
[im_header]
<pre>
$ddl
</pre>
[im_footer]
"