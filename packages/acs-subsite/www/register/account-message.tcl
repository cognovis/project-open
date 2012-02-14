ad_page_contract {
    Inform the user of an account status message.
    
    @cvs-id $Id: account-message.tcl,v 1.2 2010/10/19 20:12:42 po34demo Exp $
} {
    {message:allhtml ""}
    {return_url ""}
}

set page_title "Logged in"
set context [list $page_title]

set system_name [ad_system_name]

