ad_page_contract {
    
    Main Calendar Page
    totally redone by Ben
    
    @author Ben Adida (ben@openforce.net)
    @creation-date June 2, 2002
    @cvs-id $Id: index.tcl,v 1.18 2008/09/08 20:13:37 donb Exp $
} {
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

if { ![calendar::have_private_p -party_id $user_id] } {
    set calendar_id [calendar::new \
                        -owner_id $user_id \
                        -private_p "t" \
                        -calendar_name "Personal" \
                        -package_id $package_id]
} 

ad_returnredirect "view"    
