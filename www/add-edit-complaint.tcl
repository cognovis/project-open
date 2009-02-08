ad_page_contract {
    Page to add or edit one complaint.
    
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net

} { 
    {complaint_id ""}
    customer_id:notnull
    {supplier_id ""}
    {return_url ""}
    {object_id ""}
    {mode "edit"}
}

set page_title "[_ intranet-contacts.Edit_complaint]"
set context [list $page_title]

if { [empty_string_p $return_url] } {
    set return_url [get_referrer]
}