if { ![exists_and_not_null mode] } {
    set mode "edit"
}

ad_form -name faq_add_edit -mode $mode -action "[ad_conn package_url]admin/faq-add-edit" -form {

        faq_id:key
	{faq_name:text(text) {label "FAQ Name"} {html { size 50 }}}
	{separate_p:text(select) {label "Each Q&A on separate page"} { options {{No f} {Yes t}} } }

    } -select_query {
	select faq_name,separate_p from faqs where faq_id = :faq_id
    } -new_data {
        set user_id [ad_conn user_id]
        set creation_ip [ad_conn host] 
        set package_id [ad_conn package_id] 
	set faq_id [db_exec_plsql create_faq {}]
    } -edit_data {
        db_dml faq_edit {
            update faqs  
            set    faq_name = :faq_name, 
                   separate_p = :separate_p 
            where  faq_id = :faq_id
        } 
    } -after_submit {
        if { ![exists_and_not_null return_url] } {
            set return_url [export_vars -base one-faq { faq_id }] 
        }
        ad_returnredirect $return_url
        ad_script_abort
    }
