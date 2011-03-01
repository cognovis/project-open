# /workflow/task-finish.tcl
# Indicate that a task has been finished for a particular workflow case.

request create
request set_param task_id -datatype integer
request set_param return_url -datatype text -value "../workspace/index"




set user_id [User::getID]

# check that the task is still valid
set is_valid_task [db_string get_status ""]

if { [string equal $is_valid_task f] } {
    template::forward $return_url
}


# Get the name of the item and of the task

db_1row get_task_info "" -column_array task_info


form create task_finish -elements {
    task_id    -datatype integer -widget hidden -param
}

element create task_finish return_url \
	-datatype text \
	-widget hidden \
	-value "../workspace/index" \
	-param

element create task_finish task_name \
	-datatype text \
	-widget inform \
	-value $task_info(transition_name) \
	-label "Task"

element create task_finish title \
	-datatype text \
	-widget inform \
	-value $task_info(title) \
	-label "Title"

element create task_finish msg \
	-datatype text \
	-label "Comment" \
	-widget textarea \
	-html { rows 10 cols 40 wrap physical }

set page_title "Finish a Task"






if { [template::form is_valid task_finish] } {
    
    form get_values task_finish task_id msg

    set ip_address [ns_conn peeraddr]    
    set user_id [User::getID]

    db_transaction {
        set is_valid_task [db_string get_status ""]

        if { [string equal $is_valid_task f] } {
            db_abort_transaction
            template::request::error invalid_task \
		"task-finish.tcl - This task is no longer valid - $task_id"
            return
        }

        db_exec_plsql workflow_approve "
           begin
               content_workflow.approve(
                       task_id    => :task_id,
                       user_id    => :user_id,
                       ip_address => :ip_address,
                       msg        => :msg
                 );
            end;"

        # send email notification to the creator of the item
        workflow::notify_admin_of_finished_task $task_id

    }

    # Flush the access cache in order to clear permissions
    content::flush_access_cache $task_info(object_id)

    template::forward $return_url
}
