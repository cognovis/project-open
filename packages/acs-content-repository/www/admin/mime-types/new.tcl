ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id: new.tcl,v 1.1 2010/03/09 11:49:46 emmar Exp $

} {
    {return_url ""}
}

set doc(title) "Create a new MIME Type"
set context [list [list "./" "MIME types"] $doc(title)]

if { $return_url eq "" } {
    set return_url "./"
}

ad_form -name mime_type_new -export {return_url} -cancel_url $return_url -form {
    {mime_type:text(text)
        {label "MIME type"}
        {html {size 25}}
    }
    {label:text(text)
        {label "Description"}
        {html {size 50}}
    }
    {extension:text(text),optional
        {label "Default extension"}
        {html {size 5}}
    }
} -on_request {
} -on_submit {

    cr_create_mime_type \
        -extension $extension \
        -mime_type $mime_type \
        -description $label
    
} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort

}
