# assignments.tcl
# Display items which have been assigned to the
# current user but are currently checked out by someone else.
# The current user can "steal" the lock from the holding user.


set user_id [User::getID]

db_multirow locked_tasks get_locked_tasks ""


set page_title "Task Assignments"
