ad_page_contract { 
     
    Adds or Edit a new Q&A to a FAQ 
    @author Rocael Hernandez (roc@viaro.net) 
    @author Gerardo Morales Cadoret (gmorales@galileo.edu) 
    @creation-date 2003-11-26 

} {
    faq_id:naturalnum,notnull
    entry_id:optional
    {prev_entry_id 0}
}  -properties { 
    context:onevalue 
    title:onevalue 
    question:onevalue 
    question_q:onevalue 
    answer:onevalue 
    answer_q:onevalue 
} 
 
db_1row get_name "select faq_name from faqs where faq_id=:faq_id" 
 
if { ![ad_form_new_p -key entry_id]} {
    set page_title [_ faq.One_Question] 
    set context [list [list "one-faq?faq_id=$faq_id" "$faq_name"] "One Q&A"]
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_modify_faq
} else {
    set page_title [_ faq.Add_QA_for_faq_name] 
    set context [list [list "one-faq?faq_id=$faq_id" "$faq_name"] [_ faq.Create_new_QA]] 
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_create_faq
}


set question "" 
set answer "" 
set insert_p "f" 
set mime_type "" 
set question_q [ad_quotehtml $question] 
set answer_q [ad_quotehtml $answer] 
set user_id [ad_verify_and_get_user_id] 
set creation_ip [ad_conn host] 

ad_form -name new_quest_answ -export {faq_id creation_ip} -form {

    entry_id:key
    {prev_entry_id:text(hidden) {value $prev_entry_id}}
    {question:text(textarea) {label "Question"} {html {rows 10 cols 40 wrap soft }} {help_text {Question text in html}}}
    {answer:text(textarea) {label "Answer"} {html {rows 10 cols 40 wrap soft }} {help_text {Answer text in html}}}

} -select_query {

 select question, answer,faq_name,qa.faq_id
 from faq_q_and_as qa, faqs f
 where entry_id = :entry_id
 and f.faq_id = qa.faq_id

} -new_data {

    set page_title [_ faq.Add_QA_for_faq_name] 
    set last_entry_id $prev_entry_id 
    
    db_transaction { 

	set old_sort_key [db_string faq_sortkey_get "select sort_key from faq_q_and_as 
    where entry_id = :last_entry_id" -default 0] 
         
	if ![string equal $old_sort_key 0] {
	    set sql_update_q_and_as " 
    update faq_q_and_as 
    set sort_key = sort_key + 1 
    where sort_key > :old_sort_key" 
	    
	    db_dml faq_update $sql_update_q_and_as 
     
	    set sort_key [expr $old_sort_key + 1] 

	} else { 
		
	    set sort_key $entry_id 

	} 
    }
 
 
    db_transaction { 
	db_exec_plsql create_q_and_a { *SQL* } 
    }

} -edit_data {

db_dml q_and_a_edit "update faq_q_and_as 
                  set question = :question, 
                  answer = :answer 
                  where entry_id = :entry_id"
} -after_submit {
   ad_returnredirect "one-faq?faq_id=$faq_id"
   ad_script_abort
}




