ad_page_contract {
    
    @creation-date 2008-08-14
    @author  (malte.sussdorff@cognovis.de)

} {
    {list_id}
    {attribute_id}
}

set context "list-text"
set title "list text"

# We get the lis info
set list [::im::dynfield::List get_instance_from_db -id $list_id]

ad_form -name texts -form {
    {attribute_id:key}
    {return_url:text(hidden),optional}
    {return_url_label:text(hidden),optional}
    {list_id:integer(hidden)}
    {section_heading:text,optional 
        {label "[_ intranet-dynfield.Section_Heading]"}
    }
    {help_text:text(textarea),optional
        {label "[_ intranet-dynfield.Help_Text]"}
        {help_text "[_ intranet-dynfield.Help_Text_HT]"}
    }
    {default_value:text(textarea),optional
        {label "[_ intranet-dynfield.Default_Value]"}
        {help_text "[_ intranet-dynfield.Default_Value_HT]"}
    }
} -edit_request {
    db_0or1row texts {select section_heading,help_text from im_dynfield_type_attribute_map where attribute_id = :attribute_id and object_type_id = :list_id}
} -on_submit {
    db_dml update {update im_dynfield_type_attribute_map set section_heading = :section_heading, help_text = :help_text, default_value = :default_value where attribute_id = :attribute_id and object_type_id = :list_id}
} -after_submit {
    ::im::dynfield::Element flush -id $attribute_id -list_id $list_id
    ad_returnredirect "[$list url]"
}

ad_return_template
