# /www/admin/monitoring/analyze/state-toggle.tcl

ad_page_contract {

    Simply toggles tables in ad_monitoring_tables_estimated on or off.

    @author mbryzek@arsdigita.com
    @creation-date Mon Aug 14 02:16:43 2000
    @cvs-id $Id: state-toggle.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $

} {
    table_id:naturalnum,notnull
    { oldvalue "f" }
}


if {[catch {db_dml monitoring_update_enabled_p \
	"update ad_monitoring_tables_estimated 
         set enabled_p=decode(:oldvalue, 't', 'f', 't')
         where table_entry_id=:table_id"} errmsg]} {
    ad_return_complaint 1 "Error updating state: $errmsg"
    return
}
db_release_unused_handles

ad_returnredirect table-analyze-info
