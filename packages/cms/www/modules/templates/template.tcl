# /cms/modules/templates/template.tcl

# Assemble information for a content item.  Note this page is only
# appropriate for revisioned content items.  Non-revisioned content
# items (symlinks, extlinks and folders) have separate admin pages

# Most information on this page is included via components.

# The mount_point is used to determine the proper root context
# when querying the path to the item.

request create -params {
  template_id -datatype integer
}

# The root ID is to determine the appropriate path to the item
set root_id [cm::modules::templates::getRootFolderID]


# resolve any symlinks
set resolved_template_id [db_string get_id ""]

set template_id $resolved_template_id

# get the path
set path [db_string get_path "" -default ""]

# check for valid template_id
if { [string equal $path ""] } {
  ns_log Notice "/templates/template.tcl - BAD TEMPLATE_ID - $template_id"
  template::forward "../sitemap/index?mount_point=templates&id="
}


# get the context bar info
db_multirow context get_context ""

# find out which items this template is registered to
db_multirow items get_items ""

# find out which types this template is registered to
db_multirow types get_types ""
