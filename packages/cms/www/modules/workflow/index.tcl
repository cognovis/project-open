# Display a list of currently defined workflows

request create
request set_param id -datatype keyword -optional
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -value workflow

# workflow totals

db_1row get_stats "" -column_array wf_stats
    

# workflow tasks by transition state: content items, overdue items
db_multirow transitions get_transitions ""



# workflow tasks by user: content items, overdue items
db_multirow user_tasks get_user_tasks ""


set page_title "Workflow Statistics"
