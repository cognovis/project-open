#    @author Matthew Geddert openacs@geddert.com
#    @creation-date 2005-07-09
#    @cvs-id $Id$

if { [string is false [contact::exists_p -party_id $party_id]] } {
    error "[_ intranet-contacts.lt_The_party_id_specifie]"
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]

set return_url "[ad_conn url]?[ad_conn query]"

set list_add_options [db_list_of_lists getem {
    select ao.title, cl.list_id
      from contact_lists cl,
           acs_objects ao
     where cl.list_id = ao.object_id
       and cl.list_id not in ( select list_id from contact_list_members where party_id = :party_id )
       and cl.list_id in ( select object_id from contact_owners where owner_id = :user_id )
     order by upper(ao.title), cl.list_id
}]



if { [llength $list_add_options] > 0 } {
    set form_p 1
    set list_add_options [concat [list [list "--[_ intranet-contacts.Add_to_List]--" ""]] $list_add_options]
    ad_form \
	-action ${package_url}list-parties-add \
	-name "add_list_member" \
	-method "GET" \
	-has_submit "1" \
	-export {return_url party_id} \
        -form {
	    {list_id:integer(select) {label ""} {options $list_add_options} {html {onChange "submit()"}}}
	} -validate {
	} -on_submit {
	    #set title [string trim $title]
	    #set list_id [contact::list::new -title $title]
	    #contact::owner_add -object_id $list_id -owner_id [ad_conn user_id]
	} -after_submit {
	    #ad_returnredirect [ad_conn url]
	    #ad_script_abort
	}
    

} else {
    set form_p 0
}


db_multirow -extend {owner_p list_url delete_url} lists get_contact_lists {
    select ao.title,
           cl.list_id
      from contact_lists cl,
           acs_objects ao,
           contact_list_members clm
     where cl.list_id = ao.object_id
       and cl.list_id = clm.list_id
       and clm.party_id = :party_id
       and cl.list_id in ( select object_id from contact_owners where owner_id in ( :user_id, :package_id ))
     order by upper(ao.title), cl.list_id

} {
    set owner_p [contact::owner_p -object_id $list_id -owner_id $user_id]
    set list_url [export_vars -base $package_url -url {{search_id $list_id}}]
    set delete_url [export_vars -base ${package_url}list-parties-remove {list_id return_url party_id}]
}
