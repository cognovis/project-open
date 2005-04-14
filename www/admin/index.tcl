ad_page_contract {
    List contents of a folder
    List path of this folder
    List path of any symlinks to this folder


    @author Michael Steigman
    @creation-date October 2004
} {
    folder_id:integer
    { mount_point "sitemap" }
    { parent_id:integer ""}
    { orderby "title,asc" }
    { page:optional }
}

set original_folder_id $folder_id
set user_id [auth::require_login]
set root_id [cm::modules::${mount_point}::getRootFolderID]

permission::require_permission -party_id $user_id \
	    -object_id $folder_id -privilege admin
    
set parent_var :folder_id
    
# Resolve the symlink, if any
set resolved_id [db_string get_resolved_id ""]
    
if { $resolved_id != $folder_id } {
    set is_symlink t
    set item_id $resolved_id
    set what "Link"
} else {
    set is_symlink f
    set what "Folder"
}
    

db_1row get_info "" -column_array info
if { $info(parent_id) == 0  } {
    # at root; this will change once inheritance is set up for modules
    set parent_id ""
} else {
    set parent_id $info(parent_id)
}


# Get the index page ID
set index_page_id [db_string get_index_page_id ""]

set page_title "Content Folder - $info(label)"

# set actions "Attributes [export_vars -base attributes?mount_point=sitemap {folder_id}] \"Folder Attributes\""
set actions [list]

template::list::create \
    -name folder_items \
    -multirow folder_contents \
    -has_checkboxes \
    -key item_id \
    -page_size 50 \
    -page_query_name get_folder_contents_paginate \
    -actions $actions \
    -elements {
	title {
	    label "Name"
	    link_html { title "View this item"}
	    link_url_col item_url
	    orderby title
	}
	file_size {
	    label "Size"
	}
	publish_date {
	    label "Publish Date"
	    display_eval {
		[ad_decode $publish_status "live" \
		     [lc_time_fmt $publish_date "%q %r"] \
		     "-"]
	    }
	}
	pretty_content_type {
	    label "Type"
	}
	last_modified {
	    label "Last Modified"
	    orderby last_modified
	    display_eval {[lc_time_fmt $last_modified "%q %r"]}
	}
    } \
    -filters {
	folder_id {}
	parent_id {} 
	mount_point {}
    }


db_multirow -extend { item_url copy file_size } folder_contents get_folder_contents "" {
    switch $content_type {
	content_folder {
	    set folder_id $item_id
	    set item_url [export_vars -base index?mount_point=sitemap { folder_id parent_id }]
	}
	default {
	    set item_url [export_vars -base ../items/index?mount_point=sitemap { item_id revision_id parent_id }]
	}
    }
    if { ![ template::util::is_nil content_length ] } {
	set file_size [lc_numeric [expr $content_length / 1000.00] "%.2f"]
    } else {
	set file_size "-"
    }
    set copy [clipboard::render_bookmark sitemap $item_id [ad_conn package_url]]
}

