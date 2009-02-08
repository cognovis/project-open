ad_page_contract {
    List and manage files for a contact.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-05-24
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {upload_count:integer "1"}
    {orderby "file,asc"}
} -validate {
    contact_exists -requires {party_id} {
	if {![contact::exists_p \
		  -party_id $party_id]} {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}
contact::require_visiblity -party_id $party_id

if {$upload_count != 10} {
    set upload_count 1
}

set folder_id [application_data_link::get_linked \
		   -from_object_id $party_id \
		   -to_object_type "content_folder"]

if {[empty_string_p $folder_id]} {

    # We assume that the folder_id will definitely be empty for users This
    # is why we try if there is an organization that has the user as an
    # employee

    set organization_list [list]
    db_foreach select_employee_ids "select CASE WHEN object_id_one = :party_id THEN object_id_two ELSE object_id_one END as other_party_id
           from acs_rels,
                acs_rel_types
          where acs_rels.rel_type = acs_rel_types.rel_type
            and ( object_id_one = :party_id or object_id_two = :party_id )
            and acs_rels.rel_type = 'contact_rels_employment'" {
		lappend organization_list $other_party_id
	    }

    set folder_id [application_data_link::get_linked \
		       -from_object_id [lindex $organization_list 0] \
		       -to_object_type "content_folder"]
}

set contact_name [contact::name \
		      -party_id $party_id]
set form_elements [list {party_id:integer(hidden)}]
lappend form_elements [list {upload_count:integer(hidden)}]
lappend form_elements [list {orderby:text(hidden),optional}]
set upload_number 1

while {$upload_number <= $upload_count} {
    lappend form_elements [list -section "section$upload_number" [list legendtext "Upload File $upload_number"] [list legend [list class myClass id myID]]]
    lappend form_elements [list "upload_file${upload_number}:file(file),optional" [list label ""]]
    lappend form_elements [list "upload_title${upload_number}:text(text),optional" [list html "size 45 maxlength 100"] [list label ""]]
    incr upload_number
}

if {$upload_count == 1} {set upload_label "Upload" } else {set upload_label "[_ intranet-contacts.Done]" }

lappend form_elements [list "upload:text(submit),optional" [list "label" $upload_label]]
lappend form_elements [list "upload_more:text(submit),optional" [list "label" "[_ intranet-contacts.Upload_More]"]]

ad_form -name upload_files -html {enctype multipart/form-data} -form $form_elements -on_request {
} -on_submit {
    set upload_number 1
    set message [list]
    while {$upload_number <= $upload_count} {
	set file [set "upload_file${upload_number}"]
	set title [set "upload_title${upload_number}"]
	set filename [template::util::file::get_property filename $file]
	if {$filename != "" } {
	    set tmp_filename [template::util::file::get_property tmp_filename $file]
	    set mime_type [template::util::file::get_property mime_type $file]
	    set tmp_size [file size $tmp_filename]
	    set extension [contact::util::get_file_extension \
			       -filename $filename]
	    if {![exists_and_not_null title]} {
		regsub -all ".${extension}\$" $filename "" title
	    }
	    set filename [contact::util::generate_filename \
			      -title $title \
			      -extension $extension \
			      -party_id $party_id]
	    set revision_id [cr_import_content \
				 -storage_type "file" -title $title $party_id $tmp_filename $tmp_size $mime_type $filename]

	    content::item::set_live_revision -revision_id $revision_id

	    # if the file is an image we need to create thumbnails
	    # #/sw/bin/convert -gravity Center -crop 75x75+0+0 fred.jpg fred.jpg
	    # #/sw/bin/convert -gravity Center -geometry 100x100+0+0 04055_7.jpg
	    # fred.jpg

	    lappend message "<a href=\"files/$filename\">$title</a>"
	}
	incr upload_number
    }
    if {[llength $message] == 1} {
	set message [lindex $message 1]
	util_user_message -html -message "[_ intranet-contacts.lt_The_file_lindex_messa]"
    } elseif {[llength $message] > 1} {
	set message [join $message ", "]
	util_user_message -html -message "[_ intranet-contacts.lt_The_files_join_messag]"
    }
} -after_submit {
    if {[exists_and_not_null upload_more]} {
	ad_returnredirect [export_vars \
			       -base "files" -url {{upload_count 10}}]
    } else {
	ad_returnredirect "files"
    }
    ad_script_abort
}

template::list::create \
    -html {width 100%} \
    -name "files" \
    -multirow "files" \
    -row_pretty_plural "[_ intranet-contacts.files]" \
    -checkbox_name checkbox \
    -bulk_action_export_vars [list party_id orderby] \
    -bulk_actions [list \
	"[_ intranet-contacts.Delete]" "../files-delete" "[_ intranet-contacts.lt_Delete_the_selectted_]" \
	"[_ intranet-contacts.Update]" "../files-update" "[_ intranet-contacts.Update_filenames]" \
		   ] \
    -selected_format "normal" \
    -key item_id \
    -elements {
	file {
	    label {File}
	    display_col title
	    link_url_eval $file_url
	}
	rename {
	    label {Rename}
	    display_template {<input name="rename.@files.item_id@" value="@files.title@" size="30">
	    }
	}
	type {
	    label "[_ intranet-contacts.Type]"
	    display_col extension
	}
	creation_date {
	    label "[_ intranet-contacts.Updated_On]"
	    display_col creation_date_pretty
	}
	creation_user {
	    label "[_ intranet-contacts.Updated_By]"
	    display_col creation_user_pretty
	}
    } -filters {
    } -orderby {
	file {
	    label "[_ intranet-contacts.File]"
	    orderby_asc  "upper(cr.title) asc,  ao.creation_date desc"
	    orderby_desc "upper(cr.title) desc, ao.creation_date desc"
	    default_direction asc
	}
	creation_date {
	    label "[_ intranet-contacts.Updated_On]"
	    orderby_asc  "ao.creation_date asc"
	    orderby_desc "ao.creation_date desc"
	    default_direction desc
	}
	creation_user {
	    label "[_ intranet-contacts.Updated_By]"
	    orderby_asc  "upper(contact__name(ao.creation_user)) asc, upper(cr.title) asc"
	    orderby_desc "upper(contact__name(ao.creation_user)) desc, upper(cr.title) asc"
	    default_direction desc
	}
	default_value file,asc
    } -formats {
	normal {
	    label "[_ intranet-contacts.Table]"
	    layout table
	    row {
	    }
	}
    }

set package_url [ad_conn package_url]
db_multirow -extend {file_url extension} -unclobber files select_files "select ci.item_id,
       ci.name,
       cr.title,
       to_char(ao.creation_date,'FMMon DD FMHH12:MIam') as creation_date_pretty,
       contact__name(ao.creation_user) as creation_user_pretty
  from cr_items ci, cr_revisions cr, acs_objects ao
 where ci.parent_id = :party_id
   and ci.live_revision = cr.revision_id
   and cr.revision_id = ao.object_id
[template::list::orderby_clause \
     -orderby \
     -name "files"]" {
     set file_url "${package_url}${party_id}/files/${name}"
     set extension [lindex [split $name "."] end]
    }
if {![empty_string_p $folder_id]} {
    set package_id [lindex [fs::get_folder_package_and_root $folder_id] 0]
    set base_url [apm_package_url_from_id $package_id]
}

ad_return_template
