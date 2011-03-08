#faq/www/admin/q_and_a-edit-2.tcl

ad_page_contract {

    Edits a particular Q and A

    @author Peter Vessenes peterv@ybos.net
    @creation-date 2000-10-25
} {
    entry_id:naturalnum,notnull
    question:html
    answer:html
    
} 

ad_require_permission [ad_conn package_id] faq_modify_faq
# Don't forget to do the permissioning

db_dml q_and_a_edit "update faq_q_and_as
                  set question = :question,
                  answer = :answer
                  where entry_id = :entry_id"

set faq_id [db_string select_faq_id "select faq_id from 
                         faq_q_and_as 
                         where entry_id = :entry_id"]

ad_returnredirect "one-faq?faq_id=$faq_id"

