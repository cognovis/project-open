# Expects the following optional parameters (in each combination):
#
# recipient_id - to filter mails for a single receiver
# sender_id - to filter mails for a single sender
# package_id to filter mails for a package instance

ad_page_contract {

    @author Nima Mazloumi
    @creation-date Mon May 30 17:55:50 CEST 2005
    @cvs-id $Id$
} {
    {page:optional 1}
}

set page_title [ad_conn instance_name]
set context [list "index"]
 
ad_return_template