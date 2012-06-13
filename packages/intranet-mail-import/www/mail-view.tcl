ad_page_contract {
    view a given piece of spam
} {
    content_item_id:integer
    { view_mode "all" }
}

set current_user_id [ad_maybe_redirect_for_registration]
set body_id [db_string get_data "select body_id from acs_mail_bodies where content_item_id= :content_item_id" -default 0]

if { ![im_is_user_site_wide_or_intranet_admin $current_user_id] } {
    # Permission check
    set sql " 
	select 	count(*)	
	from 	acs_rels 
	where 
		object_id_one = :current_user_id and 
		object_id_one in ( 	
			select 	object_id_one 	
			from 	acs_rels 
			where object_id_two in (select object_id_two from acs_rels where object_id_one = :body_id) 
		)
    "
    if { 0 == [db_string get_data $sql -default 0] } { 
	ns_return 200 text/html "Mail not found"
	break
    }
}



set title ""
set context [list]

set field_list [acs_mail_body_to_output_format -body_id $body_id]

set to [lindex $field_list 0]
set from [lindex $field_list 1]
set subject [lindex $field_list 2]
set body [lindex $field_list 3]

# strip html part from html email 
if { [string first "<html>" [string tolower $body]] != -1 } {
    set start_html [string first "<html>" [string tolower $body]]
    set stop_html [string first "</html>" [string tolower $body]]
    set body [string range $body $start_html [expr $stop_html + 7]]
}

set extraheaders [lindex $field_list 4]
set send_date [db_string sent "select to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') from acs_objects where object_id=:body_id" -default ""]

set project_id [db_string get_view_id "select object_id_two from acs_rels where object_id_one =:body_id and rel_type = 'im_mail_related_to'" -default 0]

set attachment_html ""
set list_attachments ""

if { 0 != $project_id } {
    set project_path [db_string get_view_id "select project_path from im_projects where project_id =$project_id" -default 0]
    set list_attachments [im_filestorage_find_files $project_id]

    append attachment_html "<div style='width:600px;'>" 

    foreach url $list_attachments {
	set file_path [im_filestorage_project_path_helper $project_id]
	set cr_item_id [string range $url [expr [string length $file_path]+7] [expr [string length $file_path] + [string length :body_id] + 3 ] ]
	if { 0 == [string compare $body_id $cr_item_id] } {
	    set file_name [string range $url [expr [string length $file_path] + [string length $body_id] + 8] [string length $url]]
	    set file_extension [file extension $url]
	    set file_icon [im_filestorage_file_type_icon $file_extension]
	    set rel_file_path "/intranet/download/project/$project_id/mails/$body_id/$file_name"
	    append attachment_html "<div style='float:left;margin:10px;'><a href='$rel_file_path'>$file_icon</a><br><a href='$rel_file_path'>$file_name</a></div>"
	}
    }
    append attachment_html "</div>" 
}
