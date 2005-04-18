# @namespace workflow

# Procedures for applying workflow to an item in CMS

namespace eval workflow {}

ad_proc -public workflow::notify_of_assignments { case_id user_id } {

  @public notify_of_assignments

  Emails assigned users of new publishing workflow tasks

  @author Michael Pih

  @param db A database handle
  @param case_id The publishing workflow
  @param user_id The From: user when sending the email

} {

    set assignments [db_list_of_lists noa_get_assignments ""]
    
    foreach assignment $assignments {
	set transition_name [lindex $assignment 0]
	set party_id        [lindex $assignment 1]
	set title           [lindex $assignment 2]
	set deadline_pretty [lindex $assignment 3]
	set name            [lindex $assignment 4]

	set subject \
		"You Have Been Assigned A Task: $transition_name of $title"
	set message "
Dear $name,
    You have been assigned a task: $transition_name of $title.
This task is due on $deadline_pretty.
"

	set request_id [db_exec_plsql notify "
	  begin
	  :1 := acs_mail_nt.post_request(
	      party_from   => :user_id,
	      party_to     => :party_id,
	      expand_group => 'f',
	      subject      => :subject,
	      message      => :message
	  );
          end;
        "]
    }

}



ad_proc -public workflow::notify_admin_of_new_tasks { case_id transition_key } {

  @public notify_admin_of_new_tasks

  Sends email notification to the creator of an item who has been assigned
    to a specific task (author/edit/approve that item)

  @author Michael Pih

  @param db A database handle
  @param case_id The workflow of an item
  @param transition_key The name of the task


} {

    set assignments [db_list_of_lists naont_get_assignments ""]

    foreach assignment $assignments {
	set admin_id        [lindex $assignment 0]
	set transition_name [lindex $assignment 1]
	set party_id        [lindex $assignment 2]
	set title           [lindex $assignment 3]
	set deadline_pretty [lindex $assignment 4]
	set name            [lindex $assignment 5]
	set admin_name      [lindex $assignment 6]

	set subject \
		"$name Has Been Assigned A Task: $transition_name of $title"
	set message "
Dear $admin_name,
    $name has been assigned a task: $transition_name of $title.
This task is due on $deadline_pretty.
"

	set request_id [db_exec_plsql notify "
	  begin
	  :1 := acs_mail_nt.post_request(
	      party_from   => null,
	      party_to     => :admin_id,
	      expand_group => 'f',
	      subject      => :subject,
	      message      => :message
	  );
          end;
        "]
    }
}


ad_proc -public workflow::notify_admin_of_finished_task { task_id } {

  @public notify_admin_of_finished_tasks

  Notify that the admin of when a workflow task has been completed

  @author Michael Pih

  @param db A database handle
  @param task_id The task


} {

    # the user who finished the task
    set user_id [User::getID]
    set name [db_string naoft_get_name ""]

    # get the task name, the creation_user, title, and date of the item
    db_1row naoft_get_task_info ""

    set subject \
	    "Task Finished: $transition_name of $title"

    set message "Dear $admin_name,
    $name has completed the task: $transition_name of $title on $today."

    set request_id [db_exec_plsql notify "
      begin
      :1 := acs_mail_nt.post_request(
          party_from   => null,
	  party_to     => :admin_id,
	  expand_group => 'f',
	  subject      => :subject,
	  message      => :message
      );
      end;
    "]
}


ad_proc -public workflow::check_wf_permission { item_id {show_error t}} {

  @public check_wf_permission

  A permission check that Integrates user permissions with workflow tasks

  @author Michael Pih

  @param db A database handle
  @param item_id The item on which to check permissions
  @param show_error t Flag indicating whether to display an error message
                      or return t

  @return Redirects to an error page if show_error is t. If show_error is f,
  then returns t if the current user has permission to access the item, f 
  if not

} {
    set user_id [User::getID]

    set can_touch [db_string cwp_touch_info ""]

    if { [string equal $can_touch t] } {
	return t
    } else {
        if { [string equal $show_error t] } {
	  content::show_error "You cannot access this item at this time" \
		  "index"
	}
	return f
    }
}
