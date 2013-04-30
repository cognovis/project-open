# /www/admin/monitoring/analyze/load-table-names.tcl

ad_page_contract {

    Loads all new table information into ad_monitoring_tables_estimated
    
    @author mbryzek@arsdigita.com
    @creation-date Mon Aug 14 02:08:49 2000
    @cvs-id $Id: load-table-names.tcl,v 1.1.1.2 2006/08/24 14:41:39 alessandrol Exp $

} {
    { return_url index }
}


#Insert any row that doesn't exists, 

db_dml insert_missing_tables \
	"insert into ad_monitoring_tables_estimated 
         (table_entry_id, table_name)
         select ad_monitoring_tab_est_seq.nextval,table_name from user_tables ut 
         where not exists (select 1 from ad_monitoring_tables_estimated amte
                            where upper(amte.table_name)=upper(ut.table_name))"

db_release_unused_handles

#Go back to the original page
ad_returnredirect $return_url



