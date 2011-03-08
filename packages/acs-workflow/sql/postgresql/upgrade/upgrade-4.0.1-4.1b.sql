/*
 * Panels callbacks have changed.
 *
 * Instead of a Tcl callback (sick idea, we knew that all along),
 * we now store a list of URLs of templates to include.
 */

/* Drop the old column */
alter table wf_context_transition_info drop column panels_callback_tcl;

/* Add the new table instead */
create table wf_context_task_panels (
  context_key	          	varchar2(100) not null
			  	constraint wf_context_panels_context_fk
			  	references wf_contexts(context_key)
				on delete cascade,
  workflow_key            	varchar2(100) not null
			  	constraint wf_context_panels_workflow_fk
			  	references wf_workflows(workflow_key)
				on delete cascade,
  transition_key          	varchar2(100) not null,
  sort_key			integer not null,
  header 			varchar2(200) not null,
  template_url			varchar2(500) not null,
  /* table constraints */
  constraint wf_context_panels_trans_fk
  foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) 
  on delete cascade,
  constraint wf_context_panels_pk
  primary key (context_key, workflow_key, transition_key, sort_key)
);

create index wf_ctx_panl_workflow_trans_idx on wf_context_task_panels(workflow_key, transition_key);

comment on table wf_context_task_panels is '
  Holds information about the panels to be displayed on the task page.
';




/*
 * Added a Notification callback.
 *
 */

alter table wf_context_transition_info add (
  /* 
   * Notification callback
   * Will be called when a notification is sent i.e., when a transition is enabled,
   * or assignment changes.
   * signature: (task_id 	in number, 
   *             custom_arg 	in varchar2, 
   *             party_to 	in integer, 
   *             party_from 	in out integer, 
   *             subject 	in out varchar2, 
   *             body 		in out varchar2)
   */
  notification_callback		varchar2(100),
  notification_custom_arg	varchar2(4000)
);





/*
 * Enhanced comment on wf_cases.object_id
 *
 */

comment on column wf_cases.object_id is '
  A case is itself an acs_object, but moreover, a case will always be about some 
  other acs_object. E.g. for ticket-tracker, the case_id will refer to an instance of 
  the ticket-tracker-workflow, while the object_id will refer to the ticket itself.
  It is possible to have multiple cases around the same object.
';


/*
 * Added unassigned callback
 */

alter table wf_context_transition_info add (
  /*
   * Unassigned callback
   * Will be called whenever a task becomes unassigned
   * Signature: (case_id in number, transition_key in varchar2, custom_arg in varchar2)
   */
  unassigned_callback       varchar2(100),
  unassigned_custom_arg     varchar2(4000)
);


/*
 * Added access privilege
 */

alter table wf_context_transition_info add (
  /* name of the privilege we should check before allowing access
   * to task information.
   */
  access_privilege          varchar2(100)
);


/* panels_callback_tcl, notification_callback and unassigned_callback
 * affect this view. 
 */

create or replace view wf_transition_info as
select t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type,
       t.context_key, 
       ct.estimated_minutes,
       ct.enable_callback, 
       ct.enable_custom_arg,
       ct.fire_callback, 
       ct.fire_custom_arg,
       ct.assignment_callback,
       ct.assignment_custom_arg,
       ct.time_callback, 
       ct.time_custom_arg,
       ct.deadline_callback, 
       ct.deadline_custom_arg,
       ct.deadline_attribute_name,
       ct.hold_timeout_callback,
       ct.hold_timeout_custom_arg,
       ct.notification_callback,
       ct.notification_custom_arg,
       ct.unassigned_callback,
       ct.unassigned_custom_arg,
       ct.access_privilege
from   wf_transition_contexts t, wf_context_transition_info ct
where  ct.workflow_key (+) = t.workflow_key
  and  ct.transition_key (+) = t.transition_key
  and  ct.context_key (+) = t.context_key;


/* Notifications and unassigned affect this */

create or replace view wf_enabled_transitions as 
select c.case_id, 
       t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type, 
       t.context_key, 
       t.enable_callback, 
       t.enable_custom_arg,
       t.fire_callback,
       t.fire_custom_arg,
       t.assignment_callback, 
       t.assignment_custom_arg,
       t.time_callback, 
       t.time_custom_arg,
       t.deadline_callback,
       t.deadline_custom_arg,
       t.deadline_attribute_name,
       t.hold_timeout_callback, 
       t.hold_timeout_custom_arg,
       t.notification_callback,
       t.notification_custom_arg,
       t.unassigned_callback,
       t.unassigned_custom_arg,
       t.estimated_minutes,
       t.access_privilege
  from wf_transition_info t, 
       wf_cases c
 where t.workflow_key = c.workflow_key
   and t.context_key = c.context_key
   and c.state = 'active'
   and not exists 
   (select tp.place_key
    from   wf_transition_places tp
    where  tp.transition_key = t.transition_key
      and  tp.workflow_key = t.workflow_key
      and  tp.direction = 'in'
      and  not exists 
       (select tk.token_id
	from   wf_tokens tk
	where  tk.place_key = tp.place_key
	  and  tk.case_id = c.case_id
	  and  tk.state = 'free'
       )
    );
