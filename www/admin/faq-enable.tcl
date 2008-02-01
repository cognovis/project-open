ad_page_contract {
    
    enable an FAQ
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-03-06

} {
    faq_id:naturalnum,notnull
}
set package_id [ad_conn package_id]

permission::require_permission -object_id $package_id -privilege faq_delete_faq 

db_dml disable_faq {
    update faqs set disabled_p = 'f' where faq_id = :faq_id
}

ad_returnredirect "index"
