ad_page_contract {

} -query {
    edit:optional
    revision_id:optional
}



# Show or edit wiki pages
#
# @author Dave Bauer (dave@thedesignexperience.org)
# @creation-date 2004-09-03
# @arch-tag: e5d58124-f276-4a01-a61a-e85959bbe0d1
# @cvs-id $Id: page.tcl,v 1.4 2005/04/29 17:23:20 cvs Exp $

set folder_id [wiki::get_folder_id]
set name [ad_conn path_info]
if {$name == ""} {
    # the path resolves directly to a site node
    set name "index"
}
ns_log debug "
DB --------------------------------------------------------------------------------
DB DAVE debugging /var/lib/aolserver/openacs-5-1/packages/wiki/lib/page.tcl
DB --------------------------------------------------------------------------------
DB name = '${name}'
DB folder_id = '${folder_id}'
DB --------------------------------------------------------------------------------"
set item_id [content::item::get_id -item_path $name -resolve_index "t" -root_folder_id $folder_id]
if {[string equal "" $item_id]} {
    rp_form_put name [ad_conn path_info]
    rp_internal_redirect "/packages/wiki/lib/new"
    ad_script_abort
}

if {[info exists edit]} {
    set form [rp_getform]
    ns_log debug "
DB --------------------------------------------------------------------------------
DB DAVE debugging /var/lib/aolserver/openacs-5-head-cr-tcl-api/packages/wiki/lib/page.tcl
DB --------------------------------------------------------------------------------
DB form = '${form}'
DB [ns_set find $form "item_id"]
DB --------------------------------------------------------------------------------"
    if {[ns_set find $form "item_id"] < 0} {
        rp_form_put item_id $item_id
        rp_form_put name $name
    }
    rp_internal_redirect "/packages/wiki/lib/new"
}


if {![info exists revision_id]} {
    db_1row get_content "
    	select 
		content,
		title 
    	from 
		cr_revisions, 
		cr_items 
    	where 
		revision_id = latest_revision 
		and cr_items.item_id=:item_id
    "
} else {
    db_1row get_content "
    	select 
		content,
		title 
    	from 
		cr_revisions
    	where 
		revision_id = :revision_id
    "
}


set stream [Wikit::Format::TextToStream $content]
set refs [Wikit::Format::StreamToRefs $stream "wiki::get_info"]

db_multirow related_items get_related_items "
	select distinct
		cr.name, 
		cr.title, 
		cr.description 
	from 
		cr_revisionsx cr, 
		cr_items ci, 
		cr_item_rels cir 
	where 
		cir.related_object_id=:item_id 
		and cir.relation_tag='wiki_reference' 
		and ci.live_revision=cr.revision_id 
		and ci.item_id=cir.item_id
"

set content [ad_wiki_text_to_html $content "wiki::get_info"]
set context [list $title]
set focus ""
set header_stuff ""
set page_title $title

set edit_link_p [permission::permission_p \
                 -object_id $item_id \
                 -party_id [ad_conn user_id] \
                 -privilege "write"
             ]

set edit_link_p "t"

set admin_p [permission::permission_p \
                 -object_id $folder_id \
                 -party_id [ad_conn user_id] \
                 -privilege "admin"
             ]

