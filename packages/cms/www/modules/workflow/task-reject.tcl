# /workflow/task-reject.tcl
# Indicate that a task has been rejected for a particular workflow case.

request create
request set_param task_id    -datatype integer
request set_param return_url -datatype text -value "../workspace/index"


set user_id [User::getID]

# check that the task is still valid
set is_valid_task [db_string get_status ""]

if { [string equal $is_valid_task f] } {
    forward $return_url
}



# Get the name of the item and of the task
db_1row get_task_info "" -column_array task_info


# get the places I can reject to
set reject_places [db_list_of_lists get_rejects ""]

# Create the form

form create reject -elements {
    task_id -datatype integer -widget hidden -param
}

element create reject return_url \
	-datatype text \
	-widget hidden \
	-value "../workspace/index" \
	-param

element create reject task_name \
	-datatype text \
	-widget inform \
	-value $task_info(transition_name) \
	-label "Task"

element create reject title \
	-datatype text \
	-widget inform \
	-value $task_info(title) \
	-label "Title"

element create reject msg \
	-datatype text \
	-label "Comment" \
	-widget textarea  \
	-html { rows 10 cols 40 wrap physical }

element create reject transition_key \
	-datatype keyword \
	-widget select \
	-label "Regress To" \
	-options $reject_places

set page_title "Reject a Task"








# Process the form
if { [template::form is_valid reject] } {
    
    form get_values reject task_id msg transition_key

    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]

    db_transaction {
        # check that the task is still valid
        set is_valid_task [db_string is_valid_task ""]

        if { [string equal $is_valid_task f] } {
            db_abort_transaction
            template::request::error invalid_task \
		"task-reject.tcl - invalid task - $task_id"
            return
        }

        db_exec_plsql workflow_reject "
                      begin
                        content_workflow.reject(
                             task_id        => :task_id,
                             user_id        => :user_id,
                             ip_address     => :ip_address,
                             transition_key => :transition_key,
                             msg            => :msg
                         );
                       end;"
    }

    # Flush the access cache in order to clear permissions
    content::flush_access_cache $task_info(object_id)

    forward $return_url
}
