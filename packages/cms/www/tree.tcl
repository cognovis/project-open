###############################################
#
# This module generates the folder tree
# 
# Parameters: 
# state - the current state of the tree. 
#          A recursive list of items in form {id children}
# 
# user_action - designates a tree operation to perform, 
#  encoded as {action mount_point folder_id parent_folder_id}
#  (parent_folder_id is optional), where action can be one of 
#  the following:
#    expand   - expand the folder
#    collapse - collapse the folder
#    reload   - reload the folder from the database and 
#                replace it in the cache
#    set_current_folder - change the current folder by
#      marking it with the "open folder" icon
#               
# additional actions
#
# recache_folder - {mount_point folder_id} If not null, the specified 
#          folder will be reloaded from the database
#
# current_folder - The folder currently open in the right pane, in 
#  form of {mount_point folder_id parent_id}. This folder will be
#  displayed with an open-folder icon next to it. If the folder is
#  not in the tree yet, its parent will be expanded
#                  
#            
#
###############################################

# Validate the current user

set user_id [User::getID]

set output "<html>
  <style>
     body { 
       font-family: Helvetica,sans-serif;
       background-color: white
     }
     td { 
       font-family: Helvetica,sans-serif
     }
     A:link, A:visited, A:active { text-decoration: none }
  </style>
<body>

<script language=\"Javascript\">

function invokeAction(action, mount_point, folder_id) {
  form = window.document.forms\['treeFrame'\];
  form.user_action.value = action + '|' + mount_point + '|' + folder_id;
  form.submit();
  return false;
}

function recacheFolder(mount_point, folder_id) {
  form = window.document.forms\['treeFrame'\];
  form.user_action.value = 'reload|' + mount_point + '|' + folder_id;
  form.submit();
  return true;
}

function recacheTree(mount_point) {
  form = window.document.forms\['treeFrame'\];
  form.user_action.value = 'reload|' + mount_point + '|_all_';
  alert(form.user_action.value);
  form.submit();
  return true;
}

function setCurrentFolder(mount_point, folder_id, parent_id) {
  form = window.document.forms\['treeFrame'\];
  form.user_action.value = 'set_current_folder|' + mount_point + '|' +
    folder_id + '|' + parent_id;
  form.submit();
  return true;
}


function setCurrentFolderChildren(mount_point, folder_id, parent_id, new_children) {
  form = window.document.forms\['treeFrame'\];
  form.user_action.value = 'set_current_folder_children|' + mount_point + '|' +
    folder_id + '|' + parent_id + '|' + new_children;
  form.submit();
  return true;
}

function openrefreshClipboard(URL, winName, winFeatures)
{
  clipboardWin = window.open (URL,winName,winFeatures);
}

</script>

<form name=treeFrame action=\"[ns_conn url]\" method=post>
<table border=0 cellpadding=0 cellspacing=0>
"

set state [ns_queryget state]

# Get the default state if none exists
if { [template::util::is_nil state] } {
  ns_log notice "INITIALIZING FOLDER TREE"
  set state [initFolderTree $user_id]
}

# Extract the current folder (it may be overwritten by user_action)
set current_folder [ns_queryget current_folder]

# Extract the time of the last update of the tree
set update_time [ns_queryget update_time]

# Process the user action, if any

set user_action [split [ns_queryget user_action] "|"]
if { ![template::util::is_nil user_action] } {
  set action [lindex $user_action 0]
  set mount_point [lindex $user_action 1]
  set folder_id [lindex $user_action 2]
  set parent_folder_id [lindex $user_action 3]

  switch $action {
 
    expand {
      # Expand the folder
      set state [updateTreeState $user_id $state \
        $mount_point $folder_id expand $update_time]
    }

    collapse {
      # Collapse the folder
      set state [updateTreeState $user_id $state \
        $mount_point $folder_id collapse $update_time]
    }
  
    reload {
      # Reload the folder's children from the database and recache the folder
      set state [updateTreeState $user_id $state \
        $mount_point $folder_id reload $update_time]
    }
 
    set_current_folder {
      # Set the curren folder; reload it from the database   
      # If the folder is not expanded yet, expand its parent

      set state [updateTreeState $user_id $state \
        $mount_point $parent_folder_id expand $update_time]
      # Remember the new current folder
      set current_folder [list $mount_point $folder_id]
    }

    set_current_folder_children {
      # Set the current folder; set its children to whatever the
      # user has passed in
      set payload [lindex $user_action 4]
      # Expand the parent folder
      set state [updateTreeState $user_id $state \
        $mount_point $parent_folder_id expand $update_time]
      # Update the children of the current folder
      set state [updateTreeState $user_id $state \
        $mount_point $folder_id set_children $update_time $payload]
      # Remember the new current folder
      set current_folder [list $mount_point $folder_id]   
    }  
  }

} 
     
# Extract the current folder/mount point
set current_mount_point [lindex $current_folder 0]
set current_folder_id   [lindex $current_folder 1]

# State is a recursive list lists of id-s of currently expanded folders, where each item is in form
# {id children_list} 
# The top-level list stores the names of all the modules.

set mount_point ""
set control_count 0

foreach folder [fetchStateFolders $user_id state] {
 
  set mount_point [folderAccess mount_point $folder]
  set name [folderAccess name $folder]
  set folder_id [folderAccess id $folder]
  set expandable [folderAccess expandable $folder]
  set symlink [folderAccess symlink $folder]
  set level [folderAccess level $folder]
  set child_count [folderAccess child_count $folder]
  set parent_id [folderAccess parent_id $folder]

  if {$mount_point == "clipboard" && [clipboard::floats_p]} {
     set expandable "f"
  }
 
  append output "<tr>\n<td nowrap>\n"

  # indent by two spaces for each level
  for { set i 0 } { $i < $level } { incr i } {
    append output "&nbsp;&nbsp;&nbsp;&nbsp;"
  }

  # add expand or collapse control if folder is expandable
  if { $expandable == "t" } {

    if { $child_count > 0 } {
      set image_src "collapse.gif"
      set action "collapse"
    } else {
      set image_src "expand.gif"
      set action "expand" 
    }

    append output "<a href=\"javascript:invokeAction('$action', '$mount_point', '$folder_id')\">"
    append output "<img src=\"resources/$image_src\" border=0 alt=\"$action\" width=11 height=11></a>\n"

  } else {
    append output "<img width=11 height=11 src=\"resources/blank.gif\" border=0>\n"
  }
  
  # Add the folder icon
  if { [string equal $mount_point $current_mount_point] &&
       [string equal $folder_id $current_folder_id] } {
    if { [string equal $symlink t] } {
      set image_src "open-shortcut.gif"
    } else {
      set image_src "open-folder.gif"
    }
    set highlight_open "<b>"
    set highlight_close "</b>"
  } else {
    if { [string equal $symlink t] } {
      set image_src "shortcut.gif"
    } else {
      set image_src "folder.gif"
    }
    set highlight_open ""
    set highlight_close ""
  }

  set href "modules/$mount_point/index?id=$folder_id&parent_id=$parent_id&mount_point=$mount_point"
  set target_attribute "target=listFrame"
  set window_features ""

  if {$mount_point == "clipboard" && [clipboard::floats_p]} {
    set target_attribute ""
    set cms_root [ad_conn package_url]
    set href "javascript: void(openrefreshClipboard('${cms_root}$href', 'clipboardFrame', 'toolbar=no'));"
  }

  append output "
       <a href=\"$href\" $target_attribute><img 
                     width=17 height=15 name=\"${mount_point}_${folder_id}\" 
                     src=\"resources/$image_src\" border=0 alt=\"folder\"></a>$highlight_open
       <a href=\"$href\" $target_attribute>$name</a>$highlight_close\n"

  append output "</td>\n<td>&nbsp;&nbsp;</td>\n"

  # Add the select icon if appropriate

  #if { $folder_id == "" } {
  #
  #  append output "<td>&nbsp;</td>\n</tr>"
  #} else {
  #  append output "<td><a 
  #    href=\"javascript:select('$mount_point', '$folder_id')\"><img 
  #    alt=\"Select $name\" src=\"resources/treeSelect.gif\" 
  #    border=0></a></td>\n</tr>\n"
  #}
  append output "</tr>"

  incr control_count
}

set cms_root [ad_conn package_url]

append output "

</table>
<input name=state type=hidden value=\"$state\">
<input name=current_folder type=hidden value=\"$current_folder\">
<input name=user_action type=hidden value=\"\">
<input name=update_time type=hidden value=\"[clock seconds]\">

</form>

<script language=JavaScript>

// Set the current page once we are done loading
if (top.listFrame.document.location.pathname == '${cms_root}loading.html')
  top.listFrame.document.location = 'modules/workspace/index?mount_point=workspace';

</script>
"

append output "</body>\n</html>\n"

ns_return 200 text/html $output
