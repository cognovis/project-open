ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id: index.tcl,v 1.4 2010/10/19 20:12:43 po34demo Exp $
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url ""}
}

set subsite_id [ad_conn subsite_id]
set login_template [parameter::get -parameter "LoginTemplate" -package_id $subsite_id]

if {$login_template eq ""} {
    set login_template "/packages/acs-subsite/lib/login"
}

