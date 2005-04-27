--
-- acs-workflow/sql/wf-core-create.sql
--
-- Creates the data model and views for the workflow package.
--
-- @author Lars Pind (lars@pinds.com)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

----------------------------------
-- KNOWLEDGE LEVEL OBJECTS
----------------------------------


/* Create the workflow superclass */

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''workflow'',
	''Workflow'',
	''Workflow'',
	''acs_object'',
	''wf_cases'',
	''case_id'',
	null,
	''f'',
	null,
	null
	);

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

create table wf_workflows (
  workflow_key          varchar(100)
                        constraint wf_workflows_pk
                        primary key
			constraint wf_workflows_workflow_key_fk
			references acs_object_types(object_type)
			on delete cascade,
  description           text
);

comment on table wf_workflows is '
  Parent table for the workflow definition.
';

create table wf_places (
  place_key             varchar(100),
  workflow_key          varchar(100)
			constraint wf_place_workflow_fk
			references wf_workflows(workflow_key)
			on delete cascade,
  place_name            varchar(100)
			constraint wf_place_name_nn
			not null,
  -- so we can display places in some logical order --
  sort_order               integer
			constraint wf_place_order_ck
			check (sort_order > 0),
  -- table constraints --
  constraint wf_place_pk
  primary key (workflow_key, place_key),
  constraint wf_places_wf_key_place_name_un
  unique (workflow_key, place_name)
);

comment on table wf_places is '
  The circles of the petri net. These hold the tokens representing the overall
  state of the workflow.
';

create table wf_roles (
  role_key                varchar(100),
  workflow_key            varchar(100)
                          constraint wf_roles_workflow_fk
                          references wf_workflows(workflow_key)
                          on delete cascade,
  role_name               varchar(100)
                          constraint wf_role_role_name_nn
                          not null,
  -- so we can display roles in some logical order --
  sort_order              integer
                          constraint wf_roles_order_ck
                          check (sort_order > 0),
  -- table constraints --
  constraint wf_role_pk
    primary key (workflow_key, role_key),
  constraint wf_roles_wf_key_role_name_un
    unique (workflow_key, role_name)
);

comment on table wf_roles is '
  A process has certain roles associated with it, such as "submitter", 
  "reviewer", "editor", "claimant", etc. For each transition, then, you
  specify what role is to perform that task. Thus, two or more tasks can be
  performed by one and the same role, so that when the role is reassigned,
  it reflects assignments of both tasks. Users and parties are then assigned
  to roles instead of directly to tasks.
';

create table wf_transitions (
  transition_key        varchar(100),
  transition_name       varchar(100)
                        constraint wf_transition_name_nn
                        not null,
  workflow_key          varchar(100)
                        constraint wf_transition_workflow_fk
                        references wf_workflows(workflow_key)
			on delete cascade,
  -- what role does this transition belong to
  -- (only for user-triggered transitions)
  role_key              varchar(100),
  -- so we can display transitions in some logical order --
  sort_order            integer
                        constraint wf_transition_order_ck
                        check (sort_order > 0),
  trigger_type          varchar(40)
			constraint wf_transition_trigger_type_ck
			check (trigger_type in 
                          ('','automatic','user','message','time')),
  -- table constraints --
  constraint wf_transition_pk
  primary key (workflow_key, transition_key),
  constraint wf_trans_wf_key_trans_name_un
  unique (workflow_key, transition_name),
  constraint wf_transition_role_fk
    foreign key (workflow_key,role_key) references wf_roles(workflow_key,role_key)
    /* We don't do on delete cascade here, because that would mean that 
     * when a role is deleted, the transitions associated with that role would be deleted, too */
);

comment on table wf_transitions is '
  The squares in the petri net. The things that somebody (or something) actually does.
';

create table wf_arcs (
  workflow_key          varchar(100)
			constraint wf_ts_arc_workflow_fk
			references wf_workflows(workflow_key)
			on delete cascade,
  transition_key        varchar(100),
  place_key             varchar(100),
  -- direction is relative to the transition
  direction             varchar(3) 
			constraint wf_arc_direction_ck
			check (direction in ('','in','out')),
  /* Must be satisfied for the arc to be traveled by a token
   * This is the name of a PL/SQL function to execute, which must return t or f
   * Signature: (case_id in integer, workflow_key in varchar, transition_key in varchar2, 
   *             place_key in varchar, direction in varchar2, custom_arg in varchar2) 
   * return char(1)
   */
  guard_callback        varchar(100),
  guard_custom_arg      text,
  guard_description     varchar(500),
  -- table constraints --
  constraint wf_arc_pk
    primary key (workflow_key, transition_key, place_key, direction),
  constraint wf_arc_guard_on_in_arc_ck
    check (guard_callback = '' or direction = 'out'),
  constraint wf_arc_transition_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade,
  constraint wf_arc_place_fk
    foreign key (workflow_key, place_key) references wf_places(workflow_key, place_key)
    on delete cascade
);

create index wf_arcs_wf_key_trans_key_idx on wf_arcs(workflow_key, transition_key);
create index wf_arcs_wf_key_place_key_idx on wf_arcs(workflow_key, place_key);

comment on table wf_arcs is '
  The arcs of the workflow petri net.
  Arcs always go between a transition and a place.
  The direction is relative to the transition here, i.e.
  in means it goes into the transition, out means it goes
  away from the transition.
';

create table wf_transition_attribute_map (
  workflow_key	        varchar(100)
			constraint wf_trans_attr_map_workflow_fk
			references wf_workflows(workflow_key)
			on delete cascade,
  transition_key        varchar(100),
  -- so the user can decide in what order the attributes should be presented
  sort_order            integer not null,
  attribute_id          integer
			constraint wf_trans_attr_map_attribute_fk
			references acs_attributes,
  -- table constraints --
  constraint wf_trans_attr_map_pk
    primary key (workflow_key, transition_key, attribute_id),
  constraint wf_trans_attr_map_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade
);

comment on table wf_transition_attribute_map is '
  The workflow attributes that should be set when
  the given transition is fired.
';


create table wf_transition_role_assign_map (
  workflow_key	        varchar(100)
			constraint wf_role_asgn_map_workflow_fk
			references wf_workflows(workflow_key)
			on delete cascade,
  transition_key        varchar(100),
  assign_role_key	varchar(100),
  -- table constraints --
  constraint wf_role_asgn_map_pk
    primary key (workflow_key, transition_key, assign_role_key),
  constraint wf_role_asgn_map_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade,
  constraint wf_tr_role_asgn_map_asgn_fk
    foreign key (workflow_key, assign_role_key) references wf_roles(workflow_key, role_key)
    on delete cascade
);

create index wf_role_asgn_map_wf_trans_idx on wf_transition_role_assign_map(workflow_key, transition_key);
create index wf_role_asgn_map_wf_as_tr_idx on wf_transition_role_assign_map(workflow_key, assign_role_key);

comment on table wf_transition_role_assign_map is '
  When part of the output of one task is to assign users to a role,
  specify that this is the case by inserting a row here.
';

comment on column wf_transition_role_assign_map.transition_key is '
  transition_key is the assigning transition.
';

comment on column wf_transition_role_assign_map.assign_role_key is '
  assign_role_key is the role being assigned a user to.
';



/*
 * Contexts 
 */

create table wf_contexts (
  context_key	        varchar(100)
			constraint wf_context_pk
			primary key,
  context_name		varchar(100)
			constraint wf_contexts_context_name_nn
		        not null
			constraint wf_contexts_context_name_un
			unique
);

comment on table wf_contexts is '
  The context of a workflow holds everything that''s not directly 
  part of the Petri Net structure, the stuff that''s likely to
  be changed as the workflow is applied in a real business, and that
  you will want to customize across different departments of the 
  same business. It includes assignments of transitions to parties,
  the call-backs, etc.
';

/*
 * Insert a default context that all new cases will use if nothing else 
 * is defined 
 */

insert into wf_contexts (context_key, context_name) values ('default', 'Default Context');



create table wf_context_workflow_info (
  context_key                   varchar(100)
                                constraint wf_context_wf_context_fk
                                references wf_contexts
                                on delete cascade,
  workflow_key                  varchar(100)
                                constraint wf_context_wf_workflow_fk
                                references wf_workflows
                                on delete cascade,
  /* The principal is the user/party that sends out email assignment notifications 
   * And receives email when a task becomes unassigned (for more than x minutes?)
   */
  principal_party               integer
                                constraint wf_context_wf_principal_fk
                                references parties
                                on delete set null,
  -- table constraints --
  constraint wf_context_workflow_pk
    primary key (context_key, workflow_key)
);

comment on table wf_context_workflow_info is '
  Holds context-dependent information about the workflow, specifically the 
  principal user.
';


create table wf_context_transition_info (
  context_key	          	varchar(100)
			  	constraint wf_context_trans_context_fk
			  	references wf_contexts,
  workflow_key            	varchar(100)
			  	constraint wf_context_trans_workflow_fk
			  	references wf_workflows,
  transition_key          	varchar(100),
  /* information for the transition in the context */
  /* The integer of minutes this task is estimated to take */
  estimated_minutes		integer,
  /* Instructions for how to complete the task. Will be displayed on the task page. */
  instructions                  text,
  /*
   * Will be called when the transition is enabled/fired.
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2)
   */
  enable_callback         	varchar(100),
  enable_custom_arg       	text,
  fire_callback           	varchar(100),
  fire_custom_arg         	text,
  /* 
   * Must return the date that the timed transition should fire
   * Will be called when the transition is enabled
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  time_callback           	varchar(100),
  time_custom_arg         	text,
  /*
   * Returns the deadline for this task.
   * Will be called when the transition becomes enabled
   * Signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  deadline_callback       	varchar(100),
  deadline_custom_arg     	text,
  /* The name of an attribute that holds the deadline */
  deadline_attribute_name      	varchar(100),
  /*
   * Must return the date that the user's hold on the task times out.
   * called when the user starts the task.
   * signature: (case_id in integer, transition_key in varchar, custom_arg in varchar2) return date
   */
  hold_timeout_callback   	varchar(100),
  hold_timeout_custom_arg 	text,
  /* 
   * Notification callback
   * Will be called when a notification is sent i.e., when a transition is enabled,
   * or assignment changes.
   * signature: (task_id 	in integer, 
   *             custom_arg 	in varchar, 
   *             party_to 	in integer, 
   *             party_from 	in out integer, 
   *             subject 	in out varchar, 
   *             body 		in out varchar)
   */
  notification_callback		varchar(100),
  notification_custom_arg	text,
  /*
   * Callback to handle unassigned tasks.
   * Will be called when an enabled task becomes unassigned.
   * Signature: (task_id in number, custom_arg in varchar2)
   */
  unassigned_callback       varchar(100),
  unassigned_custom_arg     text,
  -- table constraints --
  constraint wf_context_trans_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade,
  constraint wf_context_transition_pk
    primary key (context_key, workflow_key, transition_key)
);

create index wf_ctx_trans_wf_trans_idx on wf_context_transition_info(workflow_key, transition_key);

comment on table wf_context_transition_info is '
  This table holds information that pertains to a transition in a specific context.
  It will specifically hold 
';


create table wf_context_role_info (
  context_key                   varchar(100)
                                constraint wf_context_role_context_fk
                                references wf_contexts(context_key)
                                on delete cascade,
  workflow_key                  varchar(100)
                                constraint wf_context_role_workflow_fk
                                references wf_workflows(workflow_key)
                                on delete cascade,
  role_key                      varchar(100),
  /* 
   * Callback to programatically assign a role.
   * Must call wordflow_case.*_role_assignment to make the assignments.
   * Will be called when a transition for that role becomes enabled
   * signature: (role_key in varchar2, custom_arg in varchar2)
   */
  assignment_callback           varchar(100),
  assignment_custom_arg         varchar(4000),
  -- table constraints --
  constraint wf_context_role_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key)
    on delete cascade,
  constraint wf_context_role_info_pk
    primary key (context_key, workflow_key, role_key)
);

comment on table wf_context_role_info is '
  This table holds context-dependent info for roles, currently only the assignment callback
';


create table wf_context_task_panels (
  context_key	          	varchar(100) not null
			  	constraint wf_context_panels_context_fk
			  	references wf_contexts(context_key)
				on delete cascade,
  workflow_key            	varchar(100) not null
			  	constraint wf_context_panels_workflow_fk
			  	references wf_workflows(workflow_key)
				on delete cascade,
  transition_key          	varchar(100) not null,
  sort_order			integer not null,
  header 			varchar(200) not null,
  template_url			varchar(500) not null,
  /* Display this panel in place of the action panel */
  overrides_action_p            char(1) default 'f'
                                constraint wf_context_panels_ovrd_p_ck
                                check (overrides_action_p in ('t','f')),
  /* Display this panel only when the task has been started (and not finished) */
  only_display_when_started_p   char(1) default 'f'
                                constraint wf_context_panels_display_p_ck
                                check (only_display_when_started_p in ('t','f')),
  -- table constraints --
  constraint wf_context_panels_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key) 
    on delete cascade,
  constraint wf_context_panels_pk
    primary key (context_key, workflow_key, transition_key, sort_order)
);

create index wf_ctx_panl_workflow_trans_idx on wf_context_task_panels(workflow_key, transition_key);

comment on table wf_context_task_panels is '
  Holds information about the panels to be displayed on the task page.
';



create table wf_context_assignments (
  context_key	          	varchar(100)
			  	constraint wf_context_assign_context_fk
			  	references wf_contexts(context_key)
				on delete cascade,
  workflow_key            	varchar(100)
			  	constraint wf_context_assign_workflow_fk
			  	references wf_workflows(workflow_key)
				on delete cascade,
  role_key			varchar(100),
  party_id			integer
				constraint wf_context_assign_party_fk
				references parties(party_id)
				on delete cascade,
  -- table constraints --
  constraint wf_context_assign_pk
    primary key (context_key, workflow_key, role_key, party_id),
  constraint wf_context_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key) 
    on delete cascade
);

create index wf_ctx_assg_workflow_trans_idx on wf_context_assignments(workflow_key, role_key);

comment on table wf_context_assignments is '
  Static (default) per-context assignments of roles to parties. 
';



------------------------------------
-- OPERATIONAL LEVEL OBJECTS
------------------------------------

create table wf_cases (
  case_id               integer
                        constraint wf_cases_pk
                        primary key
			constraint wf_cases_acs_object_fk
			references acs_objects(object_id)
			on delete cascade,
  workflow_key          varchar(100)
                        constraint wf_cases_workflow_fk
                        references wf_workflows(workflow_key)
			on delete cascade,
  context_key	        varchar(100)
			constraint wf_cases_context_fk
			references wf_contexts(context_key)
			on delete cascade,
  object_id		integer 
			constraint wf_cases_object_fk
			references acs_objects(object_id)
			on delete cascade,
  -- a toplevel state of the case 
  state        		varchar(40)
			default 'created'
			constraint wf_cases_state_ck
			check (state in ('created',
					 'active',
                                         'suspended',
                                         'canceled',
                                         'finished'))
);

create index wf_cases_workflow_key_idx on wf_cases(workflow_key);
create index wf_cases_context_key_idx on wf_cases(context_key);
create index wf_cases_object_id_idx on wf_cases(object_id);

comment on table wf_cases is '
  The instance of a process, e.g. the case of publishing one article, 
  the case of handling one insurance claim, the case of handling
  one ecommerce order, of fixing one ticket-tracker ticket.
';


comment on column wf_cases.object_id is '
  A case is generally about some other object, e.g., an insurance claim, an article,
  a ticket, an order, etc. This is the place to store the reference to that object.
  It is not uncommong to have more than one case for the same object, e.g., we might 
  have one process for evaluating and honoring an insurance claim, and another for archiving
  legal information about a claim.
';



create table wf_case_assignments (
  case_id	        integer
			constraint wf_case_assign_fk
			references wf_cases(case_id)
			on delete cascade,
  workflow_key          varchar(100),
  role_key		varchar(100),
  party_id		integer
			constraint wf_case_assign_party_fk
			references parties(party_id)
			on delete cascade,
  -- table constraints --
  constraint wf_case_assign_pk
    primary key (case_id, role_key, party_id),
  constraint wf_case_assign_role_fk
    foreign key (workflow_key, role_key) references wf_roles(workflow_key, role_key)
    on delete cascade
);

create index wf_case_assgn_party_idx on wf_case_assignments(party_id);

comment on table wf_case_assignments is '
  Manual per-case assignments of roles to parties.
';


create table wf_case_deadlines (
  case_id	        integer
			constraint wf_case_deadline_fk
			references wf_cases(case_id)
			on delete cascade,
  workflow_key          varchar(100),
  transition_key        varchar(100),
  deadline		timestamptz
			constraint wf_case_deadline_nn
			not null,
  -- table constraints --
  constraint wf_case_deadline_pk
    primary key (case_id, transition_key),
  constraint wf_case_deadline_trans_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
    on delete cascade
);


comment on table wf_case_deadlines is '
  Manual deadlines for the individual transitions (tasks) on a per-case basis.
';



create sequence t_wf_task_id_seq;
create view wf_task_id_seq as
select nextval('t_wf_task_id_seq') as nextval;

create table wf_tasks (
  task_id	        integer
			constraint wf_task_pk
			primary key,
  case_id               integer
			constraint wf_task_case_fk
			references wf_cases
			on delete cascade,
  workflow_key		varchar(100)
			constraint wf_task_workflow_fk
			references wf_workflows(workflow_key),
  transition_key 	varchar(100),
  /* Information about the task */
  state 		varchar(40)
  			default 'enabled'
			constraint wf_task_state_ck
			check (state in ('enabled','started','canceled',
                                         'finished','overridden')),
  enabled_date          timestamptz default now(),
  started_date          timestamptz,
  canceled_date         timestamptz,
  finished_date         timestamptz,
  overridden_date       timestamptz,
  /* -- TIME transition info */
  trigger_time          timestamptz,
  /* -- USER transition info */
  deadline              timestamptz,
  estimated_minutes	integer,
  holding_user          integer
			constraint wf_task_holding_user_fk
			references users(user_id)
			on delete cascade,
  hold_timeout          timestamptz,
  -- table constraints --
  constraint wf_task_transition_fk
    foreign key (workflow_key, transition_key) references wf_transitions(workflow_key, transition_key)
);

create index wf_tasks_case_id_idx on wf_tasks(case_id);

create index wf_tasks_holding_user_idx on wf_tasks(holding_user);

comment on table wf_tasks is '
  The tasks that need to be done, who can do it, and what state it''s in.
  A task is the instance of a transition.
';

create table wf_task_assignments (
  task_id               integer
			constraint wf_task_assign_task_fk
			references wf_tasks(task_id)
			on delete cascade,
  party_id              integer
			constraint wf_task_party_fk
                        references parties(party_id)
			on delete cascade,
  -- table constraints --
  constraint wf_task_assignments_pk
    primary key (task_id, party_id)
);

create index wf_task_asgn_party_id_idx on wf_task_assignments(party_id);

create sequence t_wf_token_id_seq;
create view wf_token_id_seq as
select nextval('t_wf_token_id_seq') as nextval;

create table wf_tokens (
  token_id              integer
			constraint wf_token_pk
			primary key,
  case_id       	integer
			constraint wf_token_workflow_instance_fk
			references wf_cases(case_id)
			on delete cascade,
  workflow_key 		varchar(100)
 			constraint wf_token_workflow_fk
			references wf_workflows(workflow_key),
  -- a token must always be in some place
  place_key             varchar(100),
  state                 varchar(40) default 'free'
			constraint wf_tokens_state_ck
			check (state in ('free', 'locked', 'canceled', 'consumed')),
  -- when the token is locked, by which task
  locked_task_id        integer
			constraint wf_token_task_fk
			references wf_tasks(task_id),
  -- info on state changes
  produced_date         timestamptz default current_timestamp,
  locked_date           timestamptz,
  canceled_date		timestamptz,
  consumed_date         timestamptz,
  produced_journal_id   integer
			constraint wf_token_produced_journal_fk
			references journal_entries(journal_id),
  locked_journal_id     integer
			constraint wf_token_locked_journal_fk
			references journal_entries(journal_id),
  canceled_journal_id   integer
			constraint wf_token_canceled_journal_fk
			references journal_entries(journal_id),
  consumed_journal_id   integer
			constraint wf_token_consumed_journal_fk
			references journal_entries(journal_id),
  -- table constraints --
  constraint wf_token_place_fk
    foreign key (workflow_key, place_key) references wf_places(workflow_key, place_key)
);

create index wf_tokens_case_id_idx on wf_tokens(case_id);

comment on table wf_tokens is '
  Where the tokens currently are, and what task is laying hands on it, if any.
  A token is sort of the instance of a place, except there''ll be one row here per
  token, and there can be more than one token per place.
';


/* Should evetually be done by acs_objects automatically */

create table wf_attribute_value_audit (
  case_id		integer
			constraint wf_attr_val_audit_case_fk
			references wf_cases(case_id)
			on delete cascade,
  attribute_id		integer
			constraint wf_attr_val_audit_attr_fk
			references acs_attributes(attribute_id)
			on delete cascade,
  journal_id		integer
			constraint wf_attr_val_audit_journal_fk
			references journal_entries(journal_id),
  attr_value		text,
  -- table constraints --
  constraint wf_attr_val_audit_pk
    primary key (case_id, attribute_id, journal_id)
);

create index wf_attr_val_aud_attr_id_idx on wf_attribute_value_audit(attribute_id);

comment on table wf_attribute_value_audit is '
  This table holds all the attribute values that has been set, 
  so we can track changes over the lifetime of a case.
';


/*
 * This is the cartesian product of transitions and contexts.
 * We need this in order to compute the following wf_transition_info view,
 * because Oracle won't let us outer join against more than one table.
 */
create view wf_transition_contexts as
select t.transition_key, 
       t.transition_name, 
       t.workflow_key, 
       t.sort_order, 
       t.trigger_type, 
       t.role_key,
       c.context_key,
       c.context_name
from   wf_transitions t, wf_contexts c;



/*
 * Returns all the information stored about a certain transition
 * in all contexts. You'll usually want to use this with a 
 * "where context = " clause.
 */
create view wf_transition_info as
select t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type,
       t.context_key, 
       t.role_key,
       ct.estimated_minutes,
       ct.instructions,
       ct.enable_callback, 
       ct.enable_custom_arg,
       ct.fire_callback, 
       ct.fire_custom_arg,
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
       ct.unassigned_custom_arg
from   wf_transition_contexts t LEFT OUTER JOIN wf_context_transition_info ct
on    (ct.workflow_key = t.workflow_key and 
       ct.transition_key = t.transition_key and 
       ct.context_key = t.context_key);



/*
 * Returns all the information stored about a certain role
 * in all contexts. You'll usually want to use this with a 
 * "where context = " clause.
 */
create view wf_role_info as
select r.role_key,
       r.role_name,
       r.workflow_key,
       c.context_key,
       cr.assignment_callback,
       cr.assignment_custom_arg  
from   wf_contexts c, wf_roles r LEFT OUTER JOIN wf_context_role_info cr
on    (cr.workflow_key = r.workflow_key and 
       cr.role_key = r.role_key)
where  cr.context_key = c.context_key;



/*
 * This view makes it easy to get the input/output places of a transition
 */
create view wf_transition_places as
select a.workflow_key, 
       t.transition_key, 
       p.place_key,
       p.place_name,
       p.sort_order,
       a.direction, 
       a.guard_callback,
       a.guard_custom_arg,
       a.guard_description
from   wf_arcs a, wf_places p, wf_transitions t
where  a.transition_key = t.transition_key
and    a.workflow_key   = t.workflow_key
and    p.place_key      = a.place_key
and    p.workflow_key   = a.workflow_key;


/*
 * This view returns information about all currently enabled transitions.
 * It does not include transitions that are started. This information, along
 * with additional, dynamic information, such as the user assignment or the 
 * time a timed transition triggers, is then stored in wf_tasks.
 *
 * Contrary to wf_tasks, this is authoritative, in that it queries
 * the actual state of the workflow net.
 *
 * The logic behind this view is: All transitions in all cases, for which 
 * there does not exists a place for which there is not a free token. 
 */
create view wf_enabled_transitions as 
select c.case_id, 
       t.transition_key, 
       t.transition_name, 
       t.workflow_key,
       t.sort_order, 
       t.trigger_type, 
       t.context_key, 
       t.role_key,
       t.enable_callback, 
       t.enable_custom_arg,
       t.fire_callback,
       t.fire_custom_arg,
       t.time_callback, 
       t.time_custom_arg,
       t.deadline_callback,
       t.deadline_custom_arg,
       t.deadline_attribute_name,
       t.hold_timeout_callback, 
       t.hold_timeout_custom_arg,
       t.notification_callback,
       t.notification_custom_arg,
       t.estimated_minutes,
       t.instructions,
       t.unassigned_callback,
       t.unassigned_custom_arg
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





/*
 * This view joins wf_tasks with the parties data model to figure out who can perform the tasks.
 * It should contain one row per ( user x task )
 */

/* Replaced 'unique' with 'distinct', because Stas had problems with Oracle behaving mysteriously */

create view wf_user_tasks as
select distinct ta.task_id, 
       ta.case_id, 
       ta.workflow_key,
       ta.transition_key, 
       tr.transition_name, 
       ta.enabled_date, 
       ta.started_date, 
       u.user_id, 
       ta.state, 
       ta.holding_user, 
       ta.hold_timeout,
       ta.deadline,
       ta.estimated_minutes
from   wf_tasks ta,
       wf_task_assignments tasgn,
       wf_cases c,
       wf_transition_info tr,
       party_approved_member_map m,
       users u
where  ta.state in ( 'enabled','started')
and    c.case_id = ta.case_id
and    c.state = 'active'
and    tr.transition_key = ta.transition_key
and    tr.workflow_key = ta.workflow_key
and    tr.trigger_type = 'user'
and    tr.context_key = c.context_key
and    tasgn.task_id = ta.task_id
and    m.party_id = tasgn.party_id
and    u.user_id = m.member_id;


