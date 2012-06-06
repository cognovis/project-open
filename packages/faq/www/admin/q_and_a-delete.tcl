#faq/www/admin/q_and_a-delete.tcl

ad_page_contract {
    
    delete a QandA
    @author peterv@ybos.net
    @creation-date 2000-10-25

} {
    entry_id:naturalnum,notnull
}

# We need to rethink the q-and-a permissioning.

permission::require_permission -object_id [ad_conn package_id] -privilege faq_delete_faq

db_1row get_faq_id "select faq_id from faq_q_and_as where entry_id=:entry_id"

db_transaction {
    db_exec_plsql delete_q_and_a {
	begin
	   faq.delete_q_and_a (
		    entry_id => :entry_id
	        );
	end;
    }
}

ad_returnredirect "one-faq?faq_id=$faq_id"
