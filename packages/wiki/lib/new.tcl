ad_page_contract {
    create a new wiki page
} -query {
    name
    item_id:integer,optional
}

if {"" == $name} { ad_return_complaint 1 "name is empty" }

set folder_id [wiki::get_folder_id]
set user_id [ad_conn user_id]
set ip_address [ad_conn peeraddr]

permission::require_permission \
    -object_id $folder_id \
    -party_id $user_id \
    -privilege "create"

# this is a wiki so we can always force the
# format and don't need richtext widget
set edit ""
ad_form -name new -action "new" -export {name edit} -form {
    item_id:key
    {title:text {label "Title"} {html {size 60}}}
    {content:text(textarea),optional,nospell {label "Content"} {html {rows 15 cols 60}}}
    {revision_notes:text(textarea),optional,nospell {label "Revision Notes"} {html {rows 5 cols 60}}}

} -edit_request {

    #    content::item::get -item_id $item_id
    db_1row get_item "
	select 
		cr_items.item_id, 
		title, 
		content 
	from 
		cr_items, 
		cr_revisions 
	where 
		name=:name 
		and parent_id=:folder_id 
		and latest_revision=revision_id
    "

}  -new_data {

    set item_id [content::item::new \
        -name $name \
        -parent_id $folder_id \
        -creation_user $user_id \
        -creation_ip $ip_address \
        -title $title \
        -text $content \
        -description $revision_notes \
        -is_live "t" \
        -storage_type "text" \
        -mime_type "text/x-openacs-wiki"]

} -edit_data {

    content::revision::new \
        -item_id $item_id \
        -title $title \
        -content $content \
        -description $revision_notes

# fraber: After discussion with Dave: Let's use "live_version" to indicated an approved
# version and use the latest_version for display.
#    db_dml set_live "update cr_items set live_revision=latest_revision where item_id=:item_id"

} -after_submit {    

    # do something clever with internal refs
    set stream [Wikit::Format::TextToStream $content]
    set refs [Wikit::Format::StreamToRefs $stream "wiki::get_info"]
    if {![llength $refs]} {
        set refs [list ""]
    }

    ns_log Notice "/wiki/lib/new.tcl: refs=$refs"

    db_foreach get_ids "
	select 
		ci.item_id as ref_item_id 
	from 
		cr_items ci left join cr_item_rels cr on (cr.related_object_id=:item_id) 
	where 
		ci.parent_id = :folder_id 
		and ci.name in ([template::util:::tcl_to_sql_list $refs]) 
		and cr.rel_id is null
    " {

	ns_log Notice "/wiki/lib/new.tcl: content::item::relate: item_id=$item_id, ref_item_id=$ref_item_id, relation_tag=wiki_reference"

        content::item::relate \
            -item_id $item_id \
            -object_id $ref_item_id \
            -relation_tag "wiki_reference"
    } 

    ad_returnredirect "./$name"

} 

set title ""
set context [list $title]
set header_stuff ""
set focus ""

ad_return_template


