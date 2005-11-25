ad_page_contract {
    
    upload an XML file with the dynfield data
    
    @author Toni Vila (avila@digiteix.com)
    @creation-date 2005-04-04
} {
    
} 

# security check
set user_id [ad_verify_and_get_user_id]

set form_id "flex_upload"

template::form create $form_id -html {enctype "multipart/form-data"} -action "import"

template::element create $form_id filename -type text -widget file -label "[_ intranet-dynfield.xml_file_widget_label]"
