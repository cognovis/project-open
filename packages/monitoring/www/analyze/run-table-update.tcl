# /www/admin/monitoring/analyze/run-table-update.tcl

ad_page_contract {

    Manually updates the tables. This should be used sparingly (that's
    why there are no links!) because it can bog down the server.

    @author kschmidt@arsdigita.com
    @creation-date Wed Jun 28 16:29:46 2000

    @cvs-id $Id: run-table-update.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $
} {
    
}

ad_monitoring_analyze_tables

ad_returnredirect table-analyze-info
