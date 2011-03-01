# ancestors.tcl
# show ancestors with navigational links to view them
# shows path with possible link to 'preview' the item
#   if the item is a sitemap folder and has an index item
#   if the item is not a folder and is under the sitemap mount point

request create -params {
    item_id -datatype integer
    mount_point -datatype keyword -value sitemap
    index_page_id -datatype integer -optional
}

set root_id [cm::modules::${mount_point}::getRootFolderID]

# special case - when the item_id is null, set it to the root folder
if { [template::util::is_nil item_id] } {
    set item_id $root_id
}


# Get the cookie; prepare for setting bookmarks
#set clip [clipboard::parse_cookie]

# use the appropriate icon depending on whether the item is bookmarked or not
# sets this_item(bookmark) as the icon
#set bookmark [clipboard::get_bookmark_icon $clip $mount_point $item_id]

# get the context bar info

db_multirow context get_context ""

# pass in index_page_id to improve efficiency
if { ![template::util::is_nil index_page_id] } {

    set index_page_sql ""
    set has_index_page t

} else {
    set index_page_sql [db_map index_page_p]
}

# get the path of the item

db_1row get_preview_info "" -column_array preview_info

template::util::array_to_vars preview_info
# physical_path, virtual_path, is_folder, has_index_page

if { [string equal $physical_path "../"] } {
    set display_path "/"
} else {
    if {[string equal [string index $physical_path 0] "/"]} {
        set physical_path [string range $physical_path 1 end]
    }
    set display_path "/$physical_path"
}

# preview_p - flag indicating whether the path is previewable or not
#   t => if the item is a sitemap folder and has an index item
#   t => if the item is not a folder and is under the sitemap mount point
set preview_p f
set preview_path $virtual_path

# Determine the root of the preview link. If CMS is running as a package,
# the index.vuh file should be under this root.
if { [catch {
  set root_path [ad_conn package_url]
} errmsg] } {
  set root_path ""
}

#set preview_path [ns_normalizepath "$root_path/$preview_path"]
set preview_path [ns_normalizepath "/acs-content-repository/$preview_path"]

ns_log Notice "mount_point = $mount_point"
if { [string equal $mount_point sitemap] } {
    ns_log Notice "is_folder = $is_folder, has_index_page = $has_index_page"
    if { [string equal $is_folder t] && [string equal $has_index_page t] } {
	set preview_p t
    } elseif { ![string equal $is_folder t] && \
	    ![template::util::is_nil live_revision] } {
	    set preview_p t
    }
}
ns_log Notice "preview_p = $preview_p"
# an item cannot be previewed if it has no associated template
if { [string equal $has_index_page t] } {
    set template_id [db_string get_template_id "" -default ""]
}

if { [string equal $template_id ""] } { 
    set preview_p f
}

