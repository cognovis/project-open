#faq/www/admin/q_and_a-new-2.tcl

ad_page_contract {
    
    Adds a new Q&A to a FAQ

    @author wirth@ybos.net
    @creation-date 2000-10-25

} {
    faq_id:integer,notnull,trim
    question:html,notnull,trim
    answer:html,notnull,trim
    entry_id:naturalnum,optional
    insert_p:optional
 
}

set package_id [ad_conn package_id]

ad_require_permission $package_id faq_create_faq

set user_id [ad_verify_and_get_user_id]
set creation_ip [ad_conn host]

if {$insert_p == "t" } {

  

 # this q+a being added after an existing question
 # make room - then do the insert 
    set last_entry_id $entry_id
 
    db_transaction {
    set old_sort_key [db_string faq_sortkey_get "select sort_key 
    from faq_q_and_as
    where entry_id = :last_entry_id"]

    set sql_update_q_and_as "
    update faq_q_and_as
    set sort_key = sort_key + 1
    where sort_key > :old_sort_key"

    db_dml faq_update $sql_update_q_and_as
    
    set sort_key [expr $old_sort_key + 1]
    
    set entry_id [db_nextval acs_object_id_seq]
    }

} else {
    
    db_transaction {
    set entry_id [db_nextval acs_object_id_seq]
    set sort_key $entry_id
    }
}


db_transaction {
    db_exec_plsql create_q_and_a {
        begin
            :1 := faq.new_q_and_a (
                entry_id => :entry_id,
                context_id => :faq_id,
		faq_id=> :faq_id,
                question => :question,
                answer => :answer,
		sort_key => :sort_key,
                creation_user => :user_id,
                creation_ip => :creation_ip
            );
        end;
    }
}

ad_returnredirect "one-faq?[export_url_vars faq_id]"
