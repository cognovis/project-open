# /www/admin/monitoring/analyze/table-analyze-info.tcl

ad_page_contract {

    This page queryies analyze_table_info to check to see when each table was last analyzed.

    @author mbryzek@arsdigita.com
    @creation-date Mon Aug 14 02:18:21 2000
    @cvs-id $Id: table-analyze-info.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $

} {
    { orderby "table_name" }
}

# Write out the header before we grab a db handle
ReturnHeaders
ns_write "[ad_header "Table Analysis"]<h2>Table Analysis </h2>
[ad_context_bar [list "[ad_conn package_url]analyze/index" Analyze] "View Table Analysis Status"]
<hr>
"


set table_def {
    {table_name "Table Name" {} {}}
    {percent_estimating "Percent Estimating in the Future" {}}
    {last_percent_estimated "Previous Percent Estimated" {}}
    {last_estimated "Last Estimation" {} {}}
    {enabled_p "Toggle On/Off" {} {<td>[ad_decode $enabled_p "t" "On" "f" "Off" "On"] - <a href=\state-toggle?table_id=$table_entry_id&oldvalue=$enabled_p>[ad_decode $enabled_p "t" "Turn Off" "f" "Turn On" "Turn On"]</a></td>}}
}

#A whopper of a selection, mostly big because of urls being added
# and decodes to change the appearance for ad_table

set sql "select table_name, table_entry_id,
         nvl(last_percent_estimated, 0) as last_percent_estimated,
         (percent_estimating || ' % - <a href=percent-toggle?table_id=' ||
         table_entry_id || '&oldvalue=' || percent_estimating || '>' ||  
         decode(percent_estimating,20, 'Switch to 100%', 100, 
         'Switch to 20%', 'Switch to 100%') || '</a>') as percent_estimating, 
         nvl(TO_CHAR(last_estimated, 'MM-DD-YYYY'), 'Never') as last_estimated,
         enabled_p
         from ad_monitoring_tables_estimated 
         [ad_order_by_from_sort_spec $orderby $table_def]"

#make a call to ad_table
set content [ad_table -Trows_per_page 50 -Ttable_extra_html  "width=90%" -Torderby $orderby select_tables $sql $table_def]

db_release_unused_handles

#write it out
ns_write "<blockquote>$content
<br>
Actions:
<ul>
<li><a href=\"load-table-names?returnto=table-analyze-info\">Update tables from the data dictionary</a>
</ul>
</blockquote>[ad_footer]"

