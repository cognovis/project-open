
if { ![exists_and_not_null mode] } {
    set mode "edit"
}

ad_form -name faq_add_edit -mode $mode -action "[ad_conn package_url]admin/faq-add-edit" -form {
    faq_id:key
    {faq_name:text(text) {label "#faq.Name#"} {html { size 50 }}}
    {separate_p:text(select) {label "#faq.QA_on_Separate_Pages#"} { options {{[_ faq.No] f} {[_ faq.Yes] t}} } }
} -select_query_name get_faq -new_data {
    set user_id [ad_conn user_id]
    set creation_ip [ad_conn host] 
    set package_id [ad_conn package_id] 
    set faq_id [db_exec_plsql create_faq {}]
} -edit_data {
    db_dml edit_faq {}
} -after_submit {
   if { ![exists_and_not_null return_url] } {
       set return_url [export_vars -base one-faq { faq_id }] 
   }
   ad_returnredirect $return_url
   ad_script_abort
}
