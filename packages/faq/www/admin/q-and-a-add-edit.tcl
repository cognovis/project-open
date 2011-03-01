ad_page_contract { 
    
    Adds or Edit a new Q&A to a FAQ and Categories if Parameter EnableCategoriesP is Enabled
    @author Rocael Hernandez (roc@viaro.net) 
    @author Gerardo Morales Cadoret (gmorales@galileo.edu) 
    @author Nima Mazloumi (nima.mazloumi@gmx.de)
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
    set context [list [list "one-faq?faq_id=$faq_id" "$faq_name"] [_ faq.One_Question]]
    set submit_label "[_ faq.Update_This_QA]"
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_modify_faq
} else {
    set page_title [_ faq.Add_QA_for_faq_name]
    set context [list [list "one-faq?faq_id=$faq_id" "$faq_name"] [_ faq.Create_new_QA]]
    set submit_label "[_ faq.Create_new_QA]"
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_create_faq
}


set insert_p "f"
set user_id [ad_conn user_id]
set creation_ip [ad_conn host]

# Are categories used?
set use_categories_p [parameter::get -parameter "EnableCategoriesP" -default 0]
set category_container [parameter::get -parameter "CategoryContainer"]
set package_id [ad_conn package_id]

set select_sql_query "select question, answer,faq_name,qa.faq_id
 from faq_q_and_as qa, faqs f
 where entry_id = :entry_id
 and f.faq_id = qa.faq_id"

ad_form -name new_quest_answ -method GET -export {faq_id creation_ip} -form {
    {entry_id:key}
    {prev_entry_id:text(hidden) {value $prev_entry_id}}
    {question:richtext
        {html {rows 15 cols 50} }
        {label "[_ faq.Question]"} 
        {help_text {[_ faq.Question_text_in_html]}}}
    {answer:richtext
        {html {rows 15 cols 50} }
        {label "[_ faq.Answer]"}
        {help_text {[_ faq.Answer_text_in_html]}}}
}

# customize form depending on category capabilities
if { $use_categories_p == 1 } {

    #add link do define categories
    set category_map_url [export_vars -base "[site_node::get_package_url -package_key categories]cadmin/one-object" { { object_id $package_id } }]

    #extend the form to support categories
    category::ad_form::add_widgets -form_name new_quest_answ -container_object_id $package_id -categorized_object_id [value_if_exists entry_id]

    ad_form -extend -name new_quest_answ -edit_request {
        db_1row q $select_sql_query
        set question [template::util::richtext::create $question "text/html"]
        set answer [template::util::richtext::create $answer "text/html"]
    } -on_submit {
        set category_ids [category::ad_form::get_categories -container_object_id $package_id]
        set question [template::util::richtext::get_property contents $question]
        set answer [template::util::richtext::get_property contents $answer]
    } -on_request {
    } -new_data {

	set page_title [_ faq.Add_QA_for_faq_name]
	set last_entry_id $prev_entry_id

	db_transaction {
	    set old_sort_key [db_string faq_sortkey_get "select sort_key from faq_q_and_as where entry_id = :last_entry_id" -default 0]

	    if ![string equal $old_sort_key 0] {
		set sql_update_q_and_as "update faq_q_and_as set sort_key = sort_key + 1 where sort_key > :old_sort_key"

		db_dml faq_update $sql_update_q_and_as
		set sort_key [expr $old_sort_key + 1]
	    } else {
		set sort_key $entry_id
	    }
	}

	db_transaction {
	    db_exec_plsql create_q_and_a { *SQL* }
	    category::map_object -remove_old -object_id $entry_id $category_ids
	    db_dml insert_asc_named_object "insert into acs_named_objects (object_id, object_name, package_id) values ( :entry_id, 'FAQ', :package_id)"
	}
    } -edit_data {
	db_dml q_and_a_edit "update faq_q_and_as set question = :question, answer = :answer where entry_id = :entry_id"
	db_dml insert_asc_named_object "update acs_named_objects set object_name = 'FAQ', package_id = :package_id where object_id = :entry_id"
	category::map_object -remove_old -object_id $entry_id $category_ids
    } -after_submit {
        ad_returnredirect "one-faq?faq_id=$faq_id"
        ad_script_abort
    }
} else {
    ad_form -extend -name new_quest_answ -edit_request {
        db_1row q $select_sql_query
        set question [template::util::richtext::create $question "text/html"]
        set answer [template::util::richtext::create $answer "text/html"]
    } -on_submit {
        set question [template::util::richtext::get_property contents $question]
        set answer [ template::util::richtext::get_property contents $answer]
    } -on_request {
    } -new_data {

        set page_title [_ faq.Add_QA_for_faq_name]
        set last_entry_id $prev_entry_id

        db_transaction {

            set old_sort_key [db_string faq_sortkey_get "select sort_key from faq_q_and_as where entry_id = :last_entry_id" -default 0]

            if ![string equal $old_sort_key 0] {
                set sql_update_q_and_as "update faq_q_and_as set sort_key = sort_key + 1 where sort_key > :old_sort_key"

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
        db_dml q_and_a_edit "update faq_q_and_as set question = :question, answer = :answer where entry_id = :entry_id"
    } -after_submit {
        faq::notification_delivery::do_notification $question $answer $entry_id $faq_id $user_id
	ad_returnredirect "one-faq?faq_id=$faq_id"
	ad_script_abort
    }
}

