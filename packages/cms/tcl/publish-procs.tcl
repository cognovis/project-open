###############################################################
#
# @namespace publish
# 
# @author Stanislav Freidin
#
# The procs in this namespace are useful for publishing items,
# including items inside other items, and writing items to the
# filesystem. <p>
# Specifically, the <tt>content</tt>, <tt>child</tt> and
# <tt>relation</tt> tags are defined here.
#
# @see namespace item item.html

namespace eval publish {

  variable item_id_stack  
  variable revision_html
}  



###################################################
#
# Publish procs

ad_proc -public publish::get_page_root {} {

  @public get_page_root
 
  Get the page root. All items will be published to the 
  filesystem with their URLs relative to this root.
  The page root is controlled by the PageRoot parameter in CMS.
  A relative path is relative to [ns_info pageroot]
  The default is [ns_info pageroot]
 
  @return The page root
 
  @see publish::get_template_root
  @see publish::get_publish_roots

} {

  set root_path [ad_parameter -package_id [ad_conn package_id] \
      PageRoot dummy ""]

  if { [string index $root_path 0] != "/" } {
    # Relative path, prepend server_root
    set root_path "[ns_info pageroot]/$root_path"
  }

  return [ns_normalizepath $root_path]

}

ad_proc -public publish::get_publish_roots {} {

  @public get_publish_roots
 
  Get a list of all page roots to which files may be published.
  The publish roots are controlled by the PublishRoots parameter in CMS,
  which should be a space-separated list of all the roots. Relative paths
  are relative to publish::get_page_root.
  The default is [list [publish::get_page_root]]
 
  @return A list of all the publish roots
 
  @see publish::get_template_root
  @see publish::get_page_root

} {

  set root_paths [ad_parameter -package_id [ad_conn package_id] \
      PublishRoots dummy]
  
  if { [llength $root_paths] == 0 } {
    set root_paths [list [get_page_root]]
  }

  # Resolve relative paths
  set page_root [publish::get_page_root]
  set absolute_paths [list]
  foreach path $root_paths {
    if { [string index $path 0] != "/" } {
      lappend absolute_paths [ns_normalizepath "$page_root/$path"]
    } else {
      lappend absolute_paths $path
    }
  }

  return $absolute_paths
}



ad_proc -public publish::get_template_root {} {

  @public get_template_root
 
  Get the template root. All templates are assumed to exist
  in the filesystem with their URLs relative to this root.
  The page root is controlled by the TemplateRoot parameter in CMS.
  The default is /web/yourserver/templates
 
  @return The template root
 
  @see content::get_template_root
  @see publish::get_page_root

} {
  return [content::get_template_root]
}


ad_proc -public content::get_template_path {} {

  Legacy compatibility

} {
  return [publish::get_template_root]
}


ad_proc -public publish::mkdirs { path } {

  @public mkdirs
 
  Create all the directories neccessary to save the specified file
 
  @param path 
     The path to the file that is about to be saved
 

} {

  set index [string last "/" $path]
  if { $index != -1 } {
    file mkdir [string range $path 0 [expr $index - 1]]
  } 
}



ad_proc -private publish::delete_multiple_files { url {root_path ""}} {

  @private delete_multiple_files
 
  Delete the specified URL from the filesystem, for all revisions
  
  @param url          Relative URL of the file to write
 
  @see publish::get_publish_roots
  @see publish::write_multiple_files
  @see publish::write_multiple_blobs

} {
  foreach_publish_path $url {
    ns_unlink -nocomplain $filename 
    ns_log debug "publish::delete_multiple_files: Delete file $filename"
  } $root_path
}


ad_proc -public publish::publish_revision { revision_id args} {

  @public publish_revision
 
  Render a revision for an item and write it to the filesystem. The
  revision is always rendered with the <tt>-embed</tt> option turned 
  on.
 
  @param revision_id  The revision id
 
  @option root_path {default All paths in the PublishPaths parameter}
    Write the content to this path only.
 
  @see item::get_extended_url
  @see publish::get_publish_roots
  @see publish::handle_item

} {

  template::util::get_opts $args

  if { [template::util::is_nil opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }
  ns_log debug "publish::publish_revision: root_path = $root_path"
  # Get tem id
  set item_id [item::get_item_from_revision $revision_id]
  # Render the item
  set item_content [handle_item $item_id -revision_id $revision_id -embed]

  if { ![template::util::is_nil item_content] } {
    set item_url [item::get_extended_url $item_id \
       -revision_id $revision_id -template_extension]

    write_multiple_files $item_url $item_content $root_path
  }

}


ad_proc -public publish::unpublish_item { item_id args } {

  @public unpublish_item
 
  Delete files which were created by <tt>publish_revision</tt>
 
  @param item_id   The item id
 
  @option revision_id {default The live revision}  
    The revision which is to be used for determining the item filename
 
  @option root_path {default All paths in the PublishPaths parameter}
    Write the content to this path only.
 
  @see publish::publish_revision

} {
  
  template::util::get_opts $args

  if { [template::util::is_nil opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }

  # Get revision id
  if { [template::util::is_nil opts(revision_id)] } {
    set revision_id [item::get_live_revision $item_id]
  } else {
    set revision_id $opts(revision_id)
  }
  
  # Delete the main file
  set item_url [item::get_extended_url $item_id -revision_id $revision_id]
  if { ![template::util::is_nil item_url] } {
    delete_multiple_files $item_url $root_path
  }

  # Delete the template's file
  set template_id [item::get_template_id $item_id]

  if { [template::util::is_nil template_id] } {
    return
  }

  set template_revision_id [item::get_best_revision $template_id]

  if { [template::util::is_nil template_revision_id] } {
    return
  }

  item::get_mime_info $template_revision_id mime_info   
  
  if { [info exists mime_info] } {
    set item_url [item::get_url $item_id]
    if { ![template::util::is_nil item_url] } {
      delete_multiple_files "${item_url}.$mime_info(file_extension)" $root_path
    }
  }

}







###########################################################
#
# Scheduled proc stuff


ad_proc -public publish::set_publish_status { item_id new_status {revision_id ""} } {

  @public set_publish_status
 
  Set the publish status of the item. If the status is live, publish the
  live revision of the item to the filesystem. Otherwise, unpublish
  the item from the filesystem.
 
  @param db          The database handle
  @param item_id     The item id
  @param new_status
    The new publish status. Must be "production", "expired", "ready" or
    "live"
  @param revision_id {default The live revision}
    The revision id to be used when publishing the item to the filesystem.
  
  @see publish::publish_revision
  @see publish::unpublish_item

} {


  switch $new_status {

    production - expired {
      # Delete the published files
      publish::unpublish_item $item_id
    }

    ready {
      # Assume the live revision if none is passed in
      if { [template::util::is_nil revision_id] } {
        set revision_id [item::get_live_revision $item_id]
      }

      # Live revision doesn't exist or item is not publishable, 
      # go to production
      if { [template::util::is_nil revision_id] || \
              ![item::is_publishable $item_id] } {
        set new_status "production"
      }

      # Delete the published files
      publish::unpublish_item $item_id
    }

    live {
      # Assume the live revision if none is passed in
      if { [template::util::is_nil revision_id] } {
        set revision_id [item::get_live_revision $item_id]
      } 

      # If live revision exists, publish it
      if { ![template::util::is_nil revision_id] && \
              [item::is_publishable $item_id] } {
          publish_revision $revision_id -root_path [publish::get_publish_roots]
      } else {
        # Delete the published files
        publish::unpublish_item $item_id
        set new_status "production"
      }
    }

  }

  db_dml sps_update_cr_items "update cr_items set publish_status = :new_status
                              where item_id = :item_id" 

}
     
 
ad_proc -private publish::track_publish_status {} {

  @private track_publish_status
 
  Scheduled proc which keeps the publish status updated
 
  @see publish::schedule_status_sweep

} {
  
  ns_log debug "publish::track_publish_status: Tracking publish status"

  db_transaction {

      if { [catch {

	  # Get all ready but nonlive items, make them live
          set items [db_list_of_lists tps_get_items_multilist ""]

	  # Have to do it this way, or else "no active select", since
	  # the other queries will clobber the current query
	  foreach pair $items {
	      set item_id [lindex $pair 0]
	      set live_revision [lindex $pair 1]
	      publish::set_publish_status $db $item_id live $live_revision
	  }
    

	  # Get all live but expired items, make them nonlive
          set items [db_list tps_get_items_onelist ""]
   
	  foreach item_id $items {
	      publish::set_publish_status $db $item_id expired 
	  }
    

      } errmsg] } {
	  ns_log Warning "publish::track_publish_status: error: $errmsg"
      }
  }
}


ad_proc -public publish::schedule_status_sweep { {interval ""} } {

  @public schedule_status_sweep
 
  Schedule a proc to keep track of the publish status. Resets
  the publish status to "expired" if the expiration date has passed.
  Publishes the item and sets the publish status to "live" if 
  the current status is "ready" and the scheduled publication time
  has passed.
 
  @param interval {default 3600}
    The interval, in seconds, between the sweeps of all items in
    the content repository. Lower values increase the precision
    of the publishing/expiration dates but decrease performance.
    If this parameter is not specified, the value of the 
    StatusSweepInterval parameter in the server's INI file is used 
    (if it exists).
    
  @see publish::set_publish_status
  @see publish::unschedule_status_sweep
  @see publish::track_publish_status

} {

  if { [template::util::is_nil interval] } {
    # Kludge: relies on that CMS is a singleton package
    set package_id [apm_package_id_from_key "cms"]
    if { ![template::util::is_nil package_id] } {
      set interval [ad_parameter -package_id $package_id StatusSweepInterval 3600]
      # if cms is installed but not mounted, return reasonable default
      if { $interval == "" } {
        set interval 3600
      }
    } else { 
      ns_log Warning "publish::schedule_status_sweep: unable to lookup package_id for cms defaulting to interval 3600"
      set interval 3600
    } 
  }

  ns_log notice "publish::schedule_status_sweep: Scheduling status sweep every $interval seconds"
  set proc_id [ns_schedule_proc -thread $interval publish::track_publish_status]
  cache set status_sweep_proc_id $proc_id
  
}

ad_proc -public publish::unschedule_status_sweep {} {

  @public unschedule_status_sweep
 
  Unschedule the proc which keeps track of the publish status. 
 
  @see publish::schedule_status_sweep

} {
  
  set proc_id [cache get status_sweep_proc_id]
  if { ![template::util::is_nil proc_id] } {
    ns_unschedule_proc $proc_id
  }
}
  

# Actually schedule the status sweep

publish::schedule_status_sweep

