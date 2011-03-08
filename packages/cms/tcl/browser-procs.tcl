################################################
#
# Procedures responsible for maintaining and updating the browser state.
#
# The browser state is saved as a tree, where each node in format
# {id list_of_child_nodes } 
# The ids for top-level nodes are mount point keys.
#
# All other information is cashed in the nsv shared memory, in format
# { mount_point pretty_name folder_id children_ids expandable symlink update_time }
# children_ids is a list of the ids of this folder's children.
#
# In order to build the tree, the state is traversed in the depth-first order,
# and each folder id is mapped to the appropriate folder in the cache, which contains
# all the presentation information neccessary to display it on the tree.
#
#################################################

ad_proc -public initFolderTree { user_id } {

 Initialize the workspace for the first time,
 by building a state consisting only of the top-level mount points
 Return the state

} {

  set state [list]
  foreach mount_point [buildMountPoints $user_id] {
    lappend state [stateNodeCreate [folderAccess mount_point $mount_point] [list]]
  }
  return $state

}

ad_proc -public updateTreeStateChildren { 
  user_id children 
  mount_point target_mount_point target_id 
  action level stateRef update_time payload
} {

 Recursively rebuild the tree state based on the requested expand or collapse 
 action. Rebuild the children of each folder and return them
 Payload is any extra data that needs to be passed in

} {
 
  set new_children [list]
  upvar $stateRef state

  foreach child $children {

    # If we are at the top level, retreive the mount point. 
    # Otherwise, retreive the folder id and use the passed in mount point
    if { $level == 0 } {
      set child_id ""
      set mount_point [stateNodeAccess id $child]
      set new_id $mount_point
    } else {
      set child_id [stateNodeAccess id $child]
      set new_id $child_id
    }
    
    set child_children [stateNodeAccess children $child]

    # Set up the flags that determine what we do later on
    
    # Do we need to recache the folder ?
    set folder_exists 1       
    # Do we need to merge in new children ?
    set use_new_children 0    
    # Do we get the new children from the database ?
    set get_db_children  1    

    set the_folder [getFolder $user_id $mount_point $child_id state]
    set folder_children [folderAccess children $the_folder]

    # If the folder in the db is newer than the update, retreive it from the db
    if { [folderAccess update_time $the_folder] > $update_time } {
      set folder_exists 0
      set use_new_children 1
    }

    # Perform the action if we found the target
    if { [string equal $mount_point $target_mount_point] && 
         ([string equal $child_id $target_id] || \
            [string equal $target_id _all_]) } {
      switch $action {

        collapse {
          # Collapse: empty the children list
          ns_log debug "updateTreeStateChildren: COLLAPSING: [folderPath $user_id $mount_point $target_id]"
          set child_children [list]   
        }

        expand {

          # Expand: fetch the new children list, unless the node is already expanded    
          if { [llength $child_children] == 0 } {

            # Prevent infinite recursion: clear the target
            set target_id ""
            set target_mount_point ""

            ns_log debug "updateTreeStateChildren: EXPANDING: [folderPath $user_id $mount_point $target_id]"

            # If the list is empty, retreive children from the database and recache the folder later
            if { [llength [folderAccess children $the_folder]] == 0 } {
              set folder_exists 0
            }
          } else {
            # If the folder is expanded, and we are trying to expand it again,
            # reload the folder just to make sure
            set folder_exists 0
	  }
          set use_new_children 1
        }

        reload {
          # Reload the folder if it has changed in the db 
          ns_log debug "updateTreeStateChildren: RELOADING: [folderPath $user_id $mount_point $target_id]"
          set folder_exists 0
          set use_new_children 1
        }
  
        set_children {
          # Manually set the children of a folder
          ns_log debug "updateTreeStateChildren: SYNCHRONIZING: [folderPath $user_id $mount_point $target_id]"
          set folder_children $payload
          set folder_exists 0
          set use_new_children 1
          set get_db_children 0
	}
      }
    }

    # Cache the new list of children for the folder if it was updated on the server
    if { !$folder_exists } {

      # Hit the database for the new children
      if { $get_db_children } {
        set folder_children [folderChildIDs \
           [folderAccess db_children $the_folder $user_id] $user_id]
      }

      # Figure out if the folder is expandable now
      if { [llength $folder_children] > 0 } {
        set expandable "t"
      } else {
        set expandable "f"
      }

      # Update the cache
      set the_folder [folderMutate children $the_folder $folder_children]
      set the_folder [folderMutate expandable $the_folder $expandable]
      cacheOneFolder $user_id $the_folder 1

      # Use the new children if the folder is already expanded
      if { [llength $child_children] > 0 } {
        set use_new_children 1
      }

    } 
 
    # Merge the children in the state with the children in the folder, if
    # neccessary. This ensures that, if a folder was already expanded, along
    # with its subfloders, their expanded status is preserved
    if { $use_new_children } {

      # Stuff all the children into a hashtable for easier searching
      foreach old_child $child_children {
        set hash([stateNodeAccess id $old_child]) $old_child
      } 

      # Merge the new children, preserving the sorted order
      set child_children [list]
      foreach new_child $folder_children {
        set old_child_id [stateNodeAccess id $new_child]
        # If the old child exists, use it instead of the new one
        if { ![info exists hash($old_child_id)] } {
          lappend child_children $new_child
        } else {
          lappend child_children $hash($old_child_id)
        }
      }
    }

    # recursively evaluate the children's children
    if { [llength $child_children] > 0 } {
      set sub_children [updateTreeStateChildren $user_id $child_children \
               $mount_point $target_mount_point $target_id $action \
               [expr $level + 1] state $update_time $payload]
      lappend new_children [stateNodeCreate $new_id $sub_children]
    } else {
      lappend new_children [stateNodeCreate $new_id [list]]
    }
  }
 
  return $new_children 

}


ad_proc -public updateTreeState { 
  user_id state target_mount_point 
  target_id action update_time {payload ""}
} {

 Rebuild the tree state based on user's action and return the new state

} {
  return [updateTreeStateChildren $user_id $state "" $target_mount_point \
            $target_id $action 0 state $update_time $payload]
}


ad_proc -public fetchStateFolders { user_id stateRef } {

 Get a linear rendition of the folder tree suitable for presentation

} {

  # Reference the state
  upvar $stateRef state

  set folderList [list]

  foreach node $state {

    set mount_point [stateNodeAccess id $node]
    set mount_children [stateNodeAccess children $node]    

    # Fetch the information for the mount point itself
    set mount_folder [getFolder $user_id $mount_point "" stateRef]
    lappend mount_folder 0
    lappend mount_folder [llength $mount_children]
    lappend mount_folder ""
    lappend folderList $mount_folder

    # Fetch all the children of the mount point
    fetchStateChildFolders $user_id $mount_point $mount_children folderList state 1 ""

  }

  return $folderList
}

ad_proc -public fetchStateChildFolders { user_id mount_point children folderListRef stateRef level parent_id } { 

 Recursive procedure to fetch a folder's children and add them to the linear 
 list of folders 

} {

  # access the growing folder list by reference
  upvar $folderListRef folderList
  upvar $stateRef state

  # increment the level for the children of each folder
  set nextLevel [expr $level + 1]

  foreach node $children {

    set node_id [stateNodeAccess id $node]
    set node_children [stateNodeAccess children $node]

    # Fetch the folder
    set folder [getFolder $user_id $mount_point $node_id state]
   
    # set the folder level for proper indenting
    lappend folder $level    

    # set the number of children in this folder
    lappend folder [llength $node_children]

    # Set the parent id of this folder
    lappend folder $parent_id

    # add the folder itself
    lappend folderList $folder
    
    # add child folders
    fetchStateChildFolders $user_id $mount_point $node_children folderList state $nextLevel $node_id
  }
}

ad_proc -public folderPath { user_id mount_point folder_id } {

 Retreive a "path" to the particular folder - in fact, this is a unique hash 
 key used to reference the folder in the AOLServer cache

} {
  return "${user_id}.${mount_point}.$folder_id"
}

ad_proc -public folderChildrenDB { mount_point folder_id } {

 Hit the database to retreive the list of children for the folder
 Recache the child folders if specified

} {
  ns_log debug "folderChildrenDB: DATABASE HIT: $mount_point.$folder_id"
  return [cm::modules::${mount_point}::getChildFolders $folder_id]
}   

ad_proc -public folderCreate {
   mount_point name id child_ids 
   expandable {symlink f} {update_time 0}} {

 A constructtor procedure to implement the folder abstraction

   } {
  return [list $mount_point $name $id $child_ids $expandable $symlink $update_time]
}


ad_proc -public folderAccess { op folder {user_id {}} } {

 An accessor procedure to implement the folder abstraction

} {
  
  switch $op {
    mount_point { return [lindex $folder 0] }
    name        { return [lindex $folder 1] }
    id          { return [lindex $folder 2] }
    children    { return [lindex $folder 3] }
    expandable  { return [lindex $folder 4] } 
    symlink     { return [lindex $folder 5] }
    update_time { return [lindex $folder 6] }
    level       { return [lindex $folder 7] }
    child_count { return [lindex $folder 8] }
    parent_id   { return [lindex $folder 9] } 
    path { 
      return [folderPath $user_id [lindex $folder 0] [lindex $folder 2]] 
    }
    db_children { return [folderChildrenDB [lindex $folder 0] [lindex $folder 2]] }
    default {
      error "Unknown folder attribute \"$op\" in folderAccess"
    }
  }
}

ad_proc -public folderMutate { op folder new_value } {

 A "mutator" procedure for folders; actually, just returns the new folder

} {
  
  switch $op {
    mount_point { return [lreplace $folder 0 0 $new_value] }
    name        { return [lreplace $folder 1 1 $new_value] }
    id          { return [lreplace $folder 2 2 $new_value] }
    children    { return [lreplace $folder 3 3 $new_value] }
    expandable  { return [lreplace $folder 4 4 $new_value] } 
    symlink     { return [lreplace $folder 5 5 $new_value] }  
    update_time { return [lreplace $folder 6 6 $new_value] }
    default {
      error "Unknown folder attribute \"$op\" in folderMutate"
    }
  }
}

ad_proc -public folderChildIDs { subfolder_list { user_id {}}} {

 Convert a list of folders into a list of folder IDs, caching
 the folders in the process

} {
  set child_ids [list]
  foreach subfolder $subfolder_list {
    if { ![template::util::is_nil user_id] } {
      cacheOneFolder $user_id $subfolder 1
    }
    lappend child_ids [stateNodeCreate [folderAccess id $subfolder] [list]]
  }

  return $child_ids
}


ad_proc -public stateNodeCreate { id children {selected ""}} {   

 A constructor procedure to implement the state node abstraction

} {
  
  set ret [list $id $children]

  # Only append the "selected" field if neccessary
  if { [string equal $selected "t"] } {
    lappend ret "t"
  }

  return $ret
}


ad_proc -public stateNodeAccess { op node } {

 An accessor procedure to implement the state node abstraction

} {
  switch $op {
    id         { return [lindex $node 0] }
    children   { return [lindex $node 1] }
    selected   { return [lindex $node 2] } 
  }
} 


ad_proc -public getFolder { user_id mount_point folder_id stateRef } {

 Retreive folder information for a particular id. If that id does not exist 
 in the cache, cache it. if id is the empty string, retreives the top-level 
 mount point

} {

  set folder_path [folderPath $user_id $mount_point $folder_id]

  if { ![folderIsCached $user_id $mount_point $folder_id] } {
    ns_log debug "getFolder: CACHE MISS: $folder_path"

    # Traverse the state to determine the path to the current folder, caching all the folders
    # on the path     
    upvar $stateRef state
    cacheStateFolders $user_id $mount_point $folder_id state

    # Most of the time, the above code will cache the correct folders. However, very rarely,
    # the correct parent folder will not exist in the state. For example, this will happen
    # if the server is restarted after a folder deep in the hierarchy was put on the clipboard.
    # Now, we have no choice but to go through all the folders along with their children.
    # This might do redundant work, but it should be able to cache the correct folder.

    # Cache the mount point itself, along with it peers
    buildMountPoints $user_id 

    if { ![folderIsCached $user_id $mount_point $folder_id] } {
      cacheMountPointFolders $user_id $mount_point $folder_id 
    }

    # Now, if THAT failed, then the folder was probably deleted... Give up
    if { ![folderIsCached $user_id $mount_point $folder_id] } {
      ns_log debug "getFolder: CACHE FAILED for: [folderPath $user_id $mount_point $folder_id]"
      return [list]
    }
  } 
 
  return [nsv_get browser_state $folder_path]
} 


ad_proc -public buildMountPoints { user_id } {

 Build a list of all the top-level mount points, caching them in the process

} {
  
   set mount_point_list [cm::modules::getMountPoints] 

   # Cache the mount points
   foreach mount_folder $mount_point_list {
     if { ![folderIsCached $user_id [folderAccess mount_point $mount_folder] ""] } {
       set child_ids [folderChildIDs \
         [folderAccess db_children $mount_folder] \
         $user_id ]
       cacheOneFolder $user_id [folderMutate children $mount_folder $child_ids]
     }
   }

   return $mount_point_list
}


ad_proc -public cacheOneFolder { user_id folder { override 0 }} {

 Cache an individual folder

} {
  set path [folderAccess path $folder $user_id]
  if { $override || ![nsv_exists browser_state $path] } {
    ns_log debug "cacheOneFolder: CACHING: $path $folder , override = $override"
    nsv_set browser_state $path $folder
  }
}

ad_proc -public refreshCachedFolder { user_id mount_point folder_id } {

 Change the cached update time in a folder
 If thr folder is not cached, do nothing

} {
  
  if { [folderIsCached $user_id $mount_point $folder_id] } {
    cacheOneFolder $user_id [folderMutate update_time \
                    [getFolder $user_id $mount_point $folder_id ""] \
                    [clock seconds]] 1 
  }
} 

ad_proc -public folderIsCached { user_id mount_point folder_id } {

 Return 1 if the folder is in the cache, 0 otherwise

} {
  return [nsv_exists browser_state [folderPath $user_id $mount_point $folder_id]]
}

ad_proc -public uncacheFolder { user_id mount_point folder_id } {

 Uncache a folder so that it will be reloaded from the db

} {
  set path [folderPath $user_id $mount_point $folder_id]
  # Catch in case the cached state does not exist (which could happen if
  # the server was restarted)
  catch " nsv_unset browser_state $path " dummy
}

ad_proc -public getStateFolderPath { user_id folder_id children target_folder_id } {


 Recursively traverse the path to some folder in a particular mount
 point, which is in the form
 mount_point_id parent_id_1 parent_id_2 ... folder_id
 Return the new path if the folder was found, an empty string otherwise

} {

  # if the folder is found, return it as the last element of the path  
  if { [string equal $folder_id $target_folder_id] } {
    return [list $folder_id]
  }

  foreach child $children {
    set child_id [stateNodeAccess id $child]
    set child_children [stateNodeAccess children $child]
    set new_path [getStateFolderPath $user_id $child_id $child_children $target_folder_id]
    if { ![template::util::is_nil new_path] } {
      return [concat [list $folder_id] $new_path]
    }
  }
 
  return ""
}


ad_proc -public cacheStateFolders { user_id target_mount_point target_folder_id stateRef } {

 Traverse the state tree to discover the path to a particular folder. Then, 
 cache all the folders on the path

} {
  
  upvar $stateRef state

  # Find the mount point
  foreach mount_point $state {

    if { [string equal [stateNodeAccess id $mount_point] $target_mount_point] } {
      # cache the folders along the path
      set mount_point_children [stateNodeAccess children $mount_point]
   
      foreach id \
        [getStateFolderPath $user_id "" \
          $mount_point_children $target_folder_id] {
        # Cache child folders of the current folder
        set mount_point_id [stateNodeAccess id $mount_point]
        foreach child_folder [folderChildrenDB $mount_point_id $id] {
          # Retreive the children of this folder from the db in case another
          # user has added some chilren
          set new_children [folderChildIDs [folderChildrenDB $mount_point_id \
                                                [folderAccess id $child_folder]]]

          cacheOneFolder $user_id \
            [folderMutate children $child_folder $new_children]
        }
   
      }
    }
  }
}


ad_proc -public cacheMountPointFolders { user_id mount_point target_folder_id } {

 Go through ALL children of the mount point and cache them, one by one, 
 until the target folder is found. This will do a lot of redundant work, 
 so be careful. This procedure will execute breadth-first search, in hope of 
 finding the target folder quicker.

} {

  ns_log debug "cacheMountPointFolders: CRITICAL MISS: [folderPath $user_id $mount_point $target_folder_id]"

  set queue [folderChildrenDB $mount_point ""]

  while { [llength $queue] > 0 } {

    # Pop the front folder
    set cur_folder [lindex $queue 0]
    set queue [lrange $queue 1 end]
  
    # Process it
    set cur_id [folderAccess id $cur_folder]
    set child_folders [folderChildrenDB $mount_point $cur_id]
    set new_children [folderChildIDs $child_folders]  
    cacheOneFolder $user_id [folderMutate children $cur_folder $new_children]

    # End the process if the target folder is found
    if { [string equal $cur_id $target_folder_id] } {
      return
    }

    # Append its children to the queue
    set queue [concat $queue $child_folders]
  }

}

    





