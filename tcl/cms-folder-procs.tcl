# @namespace cms_folder

# Procedures associated with the CMS folder listing

namespace eval cms_folder {}


# @public flush

# Flush the folder listing paginator cache

# @param mount_point The mount point, defaults to "sitemap"
# @param id The folder id, defaults to "" (root folder)

proc cms_folder::flush { {mount_point "sitemap"} {id ""} } {

    set cache_id "folder_contents_${mount_point}_$id"
    
    # use * to flush all sort orders for a cached datasource
    cache flush "$cache_id*"

}

# @public get_registered_types
#
# Get all the content types registered to a folder
#
# @param folder_id   The folder id
#
# @param datasource  {default multilist}
#   Either "multilist" (return a multilist, suitable for the
#   <tt>-options</tt> parameter to widgets), or "multirow"
#  (create a multirow datasource in the calling frame). The
#  multirow datasource will have two columns, <tt>pretty_name</tt>
#  and <tt>content_type</tt>
#
# @param name        {default registered_types}
#   The name for the multirow datasource. Ignored if the
#   <tt>darasource</tt> parameter is not "multirow"
#
# @see proc cms_folder::flush_registered_types

ad_proc cms_folder::get_registered_types {
  folder_id {datasource multilist} {name registered_types}
} {

  if { [string equal $datasource "multirow"] } {
      set sql [db_map get_name_type]
      return [uplevel 1 "db_multirow $name not_used \"${sql}\""]
  } else {
      return [db_list_of_lists get_name_type ""]
  }
}

# @public flush_registered_types
#
# Flushe the registered types cache for the folder
#
# @param id {default The empty string}
#   The ID of the folder to flush. If missing, all folders
#   will be flushed
#
# @see proc cms_folder::flush

proc cms_folder::flush_registered_types { {id ""} } {
  set cache_id "folder_registered_types $id"
  template::query::flush_cache "$cache_id*"
}
