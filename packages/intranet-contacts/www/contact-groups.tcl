ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {return_url "./"}
}
contact::require_visiblity -party_id $party_id

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set recipients [list]



