# /www/admin/monitoring/analyze/percent-toggle.tcl

ad_page_contract {

    Simply toggles tables in ad_monitoring_tables_estimated to 20 or 100 percent estimating#

    @param table_id The table we're modifying
    @param oldvalue The percentage of rows we're sampling

    @author mbryzek@arsdigita.com
    @creation-date Mon Aug 14 02:14:32 2000
    @cvs-id $Id: percent-toggle.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $

} {
    table_id:naturalnum,notnull
    { oldvalue:integer "" }
    
}

#Do the update.. shouldn't have problems, 

if {[catch {db_dml monitoring_sample_update \
	"update ad_monitoring_tables_estimated 
            set percent_estimating=decode(:oldvalue, 20, 100, 20)
            where table_entry_id=:table_id"} errmsg]} {
    ad_return_complaint 1 "Error updating state: $errmsg"
    return
}

db_release_unused_handles

#go back to the display page.
ad_returnredirect table-analyze-info
