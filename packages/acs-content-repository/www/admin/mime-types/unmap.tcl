ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id: unmap.tcl,v 1.1 2010/03/09 11:49:46 emmar Exp $

} {
    extension:notnull
    mime_type:notnull
    {return_url ""}
}

if { $return_url eq "" } {
    set return_url "index"
}

db_dml extension_unmap {}

ad_returnredirect $return_url
