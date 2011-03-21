# Display the next action to perform on this object, if any

# If the task is currently being performed by someone else, display that
# If the task is not currently being performed and you are assigned to it,
# have links to either check out or perform (finish) the task.

# requires: item_id

request create -params {
  item_id     -datatype integer
  mount_point -datatype keyword -optional -value sitemap
}


# Check permissions
content::check_access $item_id cm_item_workflow \
  -mount_point $mount_point \
  -return_url "modules/sitemap/index" \
  -request_error

# Look up the workflow associated with this item, if any:

#set query "select case_id, initcap(toplevel_state) state
#           from wf_cases where object_id = :item_id"

db_0or1row get_caseinfo "" -column_array caseinfo

# Look up the enabled or started transition for this workflow, if any: 

if { ! [template::util::is_nil caseinfo] } {

  set case_id $caseinfo(case_id)

  db_0or1row get_transinfo "" -column_array transinfo

  # Determine whether the current user is assigned to the active transition

  if { [array exists transinfo] } {

    set user_id [User::getID]
    set transition_key $transinfo(transition_key)

    set is_assigned [db_string get_status ""]

    # if eligible, add a link to complete this task
    if { $is_assigned } {
        set deadline [db_string get_deadline ""]
    }
  }
}


set return_url "../items/index?item_id=$item_id&mount_point=$mount_point"
