ad_page_contract { 
    Displays a form for creating a new faq or edit an existing faq. 

    @author Rocael Hernandez (roc@viaro.net) 
    @author Gerardo Morales Cadoret (gmorales@galileo.edu) 
    @creation-date 2003-11-26 
} {  
    faq_id:optional 
    return_url:optional
} -properties { 
    context:onevalue 
    faq_id:onevalue 
    title:onevalue 
    action:onevalue 
    submit_label:onevalue 
    faq_name:onevalue 
   
} 
 
set context [list [_ faq.Create_an_FAQ]]
set submit_label [_ faq.Create_FAQ] 
set faq_name "" 

if { ![ad_form_new_p -key faq_id]} { 
    set context [list [_ faq.Edit_an_FAQ]]
    set page_title [_ faq.Edit_an_FAQ] 
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_modify_faq 
} else { 
    set context [list [_ faq.Create_an_FAQ]]
    set page_title [_ faq.Create_an_FAQ]
    permission::require_permission -object_id [ad_conn package_id] -privilege faq_create_faq 
} 

