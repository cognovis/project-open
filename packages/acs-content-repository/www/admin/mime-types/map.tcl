ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id: map.tcl,v 1.1 2010/03/09 11:49:46 emmar Exp $

} {
    mime_type:notnull
    {return_url ""}
}

set doc(title) "Add an extension"

set label [db_string get_mime_type {} -default $mime_type]

set context [list [list [export_vars -base "extensions" {mime_type}] "Extensions mapped to $label"] $doc(title)]

if { $return_url eq "" } {
    set return_url [export_vars -base "extensions" {mime_type}]
}

ad_form -name extension_new -export {return_url} -cancel_url $return_url -form {
    {mime_type:text(inform)
        {label "MIME type"}
        {html {size 25}}
    }
    {label:text(inform)
        {label "Description"}
        {html {size 50}}
    }
    {extension:text(text)
        {label "Extension"}
        {html {size 5}}
    }
} -on_request {
} -on_submit {

    cr_create_mime_type \
        -extension $extension \
        -mime_type $mime_type

} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort

}
