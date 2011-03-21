-- Data model for the workflow package, part of the OpenACS system.
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @creation-date 9 January 2003
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

---------------------------------
-- Workflow level, Generic Model
---------------------------------

-- Create the workflow object type
-- We use workflow_lite rather than just workflow
-- to avoid a clash with the old workflow package acs-workflow
select acs_object_type__create_type (
    'workflow_lite',
    'Workflow Lite',
    'Workflow Lites',
    'acs_object',
    'workflows',
    'workflow_id',
    null,
    'f',
    null,
    null
);


-- A generic table for any kind of workflow implementation
-- Currently, the table only holds FSM workflows but when 
-- other types of workflows are added we will add a table
-- to hold workflow_types and reference that table from
-- this workflows table.
create table workflows (
  workflow_id             integer
                          constraint wfs_pk
                          primary key
                          constraint wfs_workflow_id_fk
                          references acs_objects(object_id)
                          on delete cascade,
  short_name              varchar(100)
                          constraint wfs_short_name_nn
                          not null,
  pretty_name             varchar(200)
                          constraint wfs_pretty_name_nn
                          not null,
  object_id               integer
                          constraint wfs_object_id_fk
                          references acs_objects(object_id)
                          on delete cascade,
  package_key             varchar(100)
                          constraint wfs_package_key_nn
                          not null
                          constraint wfs_apm_package_types_fk
                          references apm_package_types(package_key),
  -- object_id points to either a package type, package instance, or single workflow case
  -- For Bug Tracker, every package instance will get its own workflow instance that is a copy
  -- of the workflow instance for the Bug Tracker package type
  object_type             varchar(1000)
                          constraint wfs_object_type_nn
                          not null
                          constraint wfs_object_type_fk
                          references acs_object_types(object_type)
                          on delete cascade,
  description             text,
  description_mime_type   varchar(200),
  constraint wfs_oid_sn_un
  unique (package_key, object_id, short_name)
);

-- For callbacks on workflow
create table workflow_callbacks (
  workflow_id             integer
                          constraint wf_cbks_wid_nn
                          not null
                          constraint wf_cbks_wid_fk
                          references workflows(workflow_id)
                          on delete cascade,
  acs_sc_impl_id          integer
                          constraint wf_cbks_sci_nn
                          not null
                          constraint wf_cbks_sci_fk
                          references acs_sc_impls(impl_id)
                          on delete cascade,
  sort_order              integer
                          constraint wf_cbks_so_nn
                          not null,
  constraint wf_cbks_pk
  primary key (workflow_id, acs_sc_impl_id)
);

create table workflow_roles (
  role_id                 integer
                          constraint wf_roles_pk
                          primary key,
  workflow_id             integer
                          constraint wf_roles_workflow_id_nn
                          not null
                          constraint wf_roles_workflow_id_fk
                          references workflows(workflow_id)
                          on delete cascade,
  short_name              varchar(100)
                          constraint wf_roles_short_name_nn
                          not null,
  pretty_name             varchar(200)
                          constraint wf_roles_pretty_name_nn
                          not null,
  sort_order              integer
                          constraint wf_roles_so_nn
                          not null,
  constraint wf_roles_short_name_un
  unique (workflow_id, short_name),
  constraint wf_roles_pretty_name_un
  unique (workflow_id, pretty_name)
);

create sequence workflow_roles_seq;

-- Callbacks for roles
create table workflow_role_callbacks (
  role_id                 integer
                          constraint wf_role_cbks_role_id_nn
                          not null
                          constraint wf_role_cbks_role_id_fk
                          references workflow_roles(role_id)
                          on delete cascade,
  acs_sc_impl_id          integer
                          constraint wf_role_cbks_contract_id_nn
                          not null
                          constraint wf_role_cbks_contract_id_fk
                          references acs_sc_impls(impl_id)
                          on delete cascade,
  -- this should be an implementation of any of the three assignment
  -- service contracts: DefaultAssignee, AssigneePickList, or 
  -- AssigneeSubQuery
  sort_order              integer
                          constraint wf_role_cbks_sort_order_nn
                          not null,
  constraint wf_role_cbks_pk
  primary key (role_id, acs_sc_impl_id),
  constraint wf_role_asgn_rol_sort_un
  unique (role_id, sort_order)
);

create table workflow_actions (
  action_id                 integer
                            constraint wf_acns_pk
                            primary key,
  workflow_id               integer
                            constraint wf_acns_workflow_id_nn
                            not null
                            constraint wf_acns_workflow_id_fk
                            references workflows(workflow_id)
                            on delete cascade,
  sort_order                integer
                            constraint wf_acns_sort_order_nn
                            not null,
  short_name                varchar(100)
                            constraint wf_acns_short_name_nn
                            not null,
  pretty_name               varchar(200)
                            constraint wf_acns_pretty_name_nn
                            not null,
  pretty_past_tense         varchar(200),
  description               text,
  description_mime_type     varchar(200),
  edit_fields               varchar(4000),
  assigned_role             integer
                            constraint wf_acns_assigned_role_fk
                            references workflow_roles(role_id)
                            on delete set null,
  always_enabled_p          bool default 'f',
  -- When the action to automatically fire.
  -- A value of 0 means immediately, null means never.
  -- Other values mean x amount of time after having become enabled
  timeout                   interval,
  parent_action_id          integer
                            constraint wf_acns_parent_action_fk
                            references workflow_actions(action_id)
                            on delete cascade,
  trigger_type              varchar(50)
                            constraint wf_acns_trigger_type_ck
                            check (trigger_type in ('user','auto','init','time','message','parallel','workflow','dynamic'))
                            default 'user',
  constraint wf_actions_short_name_un
  unique (workflow_id, short_name),
  constraint wf_actions_pretty_name_un
  unique (workflow_id, parent_action_id, pretty_name)
);

create sequence workflow_actions_seq;

-- Determines which roles are allowed to take certain actions
create table workflow_action_allowed_roles (
  action_id               integer
                          constraint wf_acn_alwd_roles_acn_id_nn
                          not null
                          constraint wf_acn_alwd_roles_acn_id_fk
                          references workflow_actions(action_id)
                          on delete cascade,
  role_id                 integer
                          constraint wf_acn_alwd_roles_role_id_nn
                          not null
                          constraint wf_acn_alwd_roles_role_id_fk
                          references workflow_roles(role_id)
                          on delete cascade,
  constraint wf_acn_alwd_roles_pk
  primary key (action_id, role_id)
);

-- Determines which privileges (on the object treated by a workflow case) will allow
-- users to take certain actions
create table workflow_action_privileges (
  action_id               integer
                          constraint wf_acn_priv_acn_id_nn
                          not null
                          constraint wf_acn_priv_acn_id_fk
                          references workflow_actions(action_id)
                          on delete cascade,
  privilege               varchar(100)
                          constraint wf_acn_priv_privilege_nn
                          not null
                          constraint wf_acn_priv_privilege_fk
                          references acs_privileges(privilege)
                          on delete cascade,
  constraint wf_acn_priv_pk
  primary key (action_id, privilege)
);

-- For callbacks on actions
create table workflow_action_callbacks (
  action_id               integer
                          constraint wf_acn_cbks_acn_id_nn
                          not null
                          constraint wf_acn_cbks_acn_id_fk
                          references workflow_actions(action_id)
                          on delete cascade,
  acs_sc_impl_id          integer
                          constraint wf_acn_cbks_sci_nn
                          not null
                          constraint wf_acn_cbks_sci_fk
                          references acs_sc_impls(impl_id)
                          on delete cascade,
  sort_order              integer
                          constraint wf_acn_cbks_sort_order_nn
                          not null,
  constraint wf_acn_cbks_pk
  primary key (action_id, acs_sc_impl_id)
);

---------------------------------
-- Workflow level, Finite State Machine Model
---------------------------------

create sequence workflow_fsm_states_seq;

create table workflow_fsm_states (
  state_id                  integer
                            constraint wf_fsm_states_pk
                            primary key,
  workflow_id               integer
                            constraint wf_fsm_states_workflow_id_nn
                            not null
                            constraint wf_fsm_states_workflow_id_fk
                            references workflows(workflow_id)
                            on delete cascade,
  parent_action_id          integer
                            constraint wf_fsm_states_parent_action_fk
                            references workflow_actions(action_id)
                            on delete cascade,
  sort_order                integer
                            constraint wf_fsm_states_sort_order_nn
                            not null,
  -- The state with the lowest sort order is the initial state
  short_name                varchar(100)
                            constraint wf_fsm_states_short_name_nn
                            not null,
  pretty_name               varchar(200)
                            constraint wf_fsm_states_pretty_name_nn
                            not null,
  hide_fields               varchar(4000),
  constraint wf_fsm_states_short_name_un
  unique (workflow_id, short_name),
  constraint wf_fsm_states_pretty_name_un
  unique (workflow_id, parent_action_id, pretty_name)
);

create index wf_fsm_states_workflow_idx on workflow_fsm_states(workflow_id);
create index wf_fsm_states_prnt_action_idx on workflow_fsm_states(parent_action_id);


create table workflow_fsm_actions (
  action_id               integer
                          constraint wf_fsm_acns_aid_fk
                          references workflow_actions(action_id)
                          on delete cascade
                          constraint wf_fsm_acns_pk
                          primary key,
  new_state               integer
                          constraint wf_fsm_acns_new_st_fk
                          references workflow_fsm_states(state_id)
                          on delete set null
  -- can be null
);

-- If an action is enabled in all states it won't have any entries in this table
create table workflow_fsm_action_en_in_st (
  action_id               integer
                          constraint wf_fsm_acn_enb_in_st_acn_id_nn
                          not null
                          constraint wf_fsm_acn_enb_in_st_acn_id_fk
                          references workflow_actions(action_id)
                          on delete cascade,
  state_id                integer
                          constraint wf_fsm_acn_enb_in_st_st_id_nn
                          not null
                          constraint wf_fsm_acn_enb_in_st_st_id_fk
                          references workflow_fsm_states
                          on delete cascade,
  assigned_p              boolean default 't',
  -- The users in the role assigned to an action are only assigned to take action
  -- in the enabled states that have the assigned_p flag
  -- set to true. For example, in Bug Tracker, the resolve action is enabled
  -- in both the open and resolved states but only has assigned_p set to true
  -- in the open state.
  constraint workflow_fsm_action_en_in_st_pk
  primary key (action_id, state_id)
);

create index wf_fsm_act_en_in_st_action_idx on workflow_fsm_action_en_in_st(action_id);
create index wf_fsm_act_en_in_st_state_idx on workflow_fsm_action_en_in_st(state_id);

--------------------------------------------------------
-- Workflow level, context-dependent (assignments, etc.)
--------------------------------------------------------


-- Static role-party map
create table workflow_role_default_parties (
  role_id                 integer
                          constraint wf_role_default_parties_rid_nn
                          not null
                          constraint wf_role_default_parties_rid_fk
                          references workflow_roles(role_id)
                          on delete cascade,
  party_id                integer
                          constraint wf_role_default_parties_pid_nn
                          not null
                          constraint wf_role_default_parties_pid_fk
                          references parties(party_id)
                          on delete cascade,
  constraint wf_role_default_parties_pk
  primary key (role_id, party_id)
);

-- Static map between roles and parties allowed to be in those roles
create table workflow_role_allowed_parties (
  role_id                 integer
                          constraint wf_role_alwd_parties_rid_nn
                          not null
                          constraint wf_role_alwd_parties_rid_fk
                          references workflow_roles(role_id)
                          on delete cascade,
  party_id                integer
                          constraint wf_role_alwd_parties_pid_nn
                          not null
                          constraint wf_role_alwd_parties_pid_fk
                          references parties(party_id)
                          on delete cascade,
  constraint wf_role_alwd_parties_pk
  primary key (role_id, party_id)
);




---------------------------------
-- Case level, Generic Model
---------------------------------

create sequence workflow_cases_seq;

create table workflow_cases (
  case_id                   integer
                            constraint workflow_cases_pk
                            primary key,
  workflow_id               integer
                            constraint wf_cases_workflow_id_nn
                            not null
                            constraint wf_cases_workflow_id_fk
                            references workflows(workflow_id)
                            on delete cascade,
  object_id                 integer
                            constraint wf_cases_object_id_fk
                            references acs_objects(object_id)
                            on delete cascade
);

create index workflow_cases_workflow_id on workflow_cases (workflow_id);

create table workflow_case_role_party_map (
  case_id                 integer
                          constraint wf_case_role_pty_map_case_id_nn
                          not null
                          constraint wf_case_role_pty_map_case_id_fk
                          references workflow_cases(case_id)
                          on delete cascade,
  role_id                 integer
                          constraint wf_case_role_pty_map_role_id_nn
                          not null
                          constraint wf_case_role_pty_map_role_id_fk
                          references workflow_roles(role_id)
                          on delete cascade,
  party_id                integer
                          constraint wf_case_role_pty_map_pty_id_nn
                          not null
                          constraint wf_case_role_pty_map_pty_id_fk
                          references parties(party_id)
                          on delete cascade,
  constraint wf_case_role_pty_map_pk
  primary key (case_id, role_id, party_id)
);

create sequence workflow_case_enbl_act_seq;

create table workflow_case_enabled_actions(
  enabled_action_id         integer
                            constraint wf_case_enbl_act_case_id_pk
                            primary key,
  case_id                   integer
                            constraint wf_case_enbl_act_case_id_nn
                            not null
                            constraint wf_case_enbl_act_case_id_fk
                            references workflow_cases(case_id)
                            on delete cascade,
  action_id                 integer
                            constraint wf_case_enbl_act_action_id_nn
                            not null
                            constraint wf_case_enbl_act_action_id_fk
                            references workflow_actions(action_id)
                            on delete cascade,
  parent_enabled_action_id  integer
                            constraint wf_case_enbl_act_parent_id_fk
                            references workflow_case_enabled_actions(enabled_action_id)
                            on delete cascade,
  assigned_p                boolean default 'f',
  completed_p               boolean default 'f',
  -- TOOD: trigger_type, assigned_role, use_action_assignees_p ...
  execution_time            timestamptz
);

create index wf_case_enbl_act_case_idx on workflow_case_enabled_actions(case_id);
create index wf_case_enbl_act_action_idx on workflow_case_enabled_actions(action_id);
create index wf_case_enbl_act_parent_idx on workflow_case_enabled_actions(parent_enabled_action_id);

create table workflow_case_action_assignees(
  enabled_action_id         integer
                            constraint wf_case_actn_asgn_enbld_actn_fk
                            references workflow_case_enabled_actions
                            on delete cascade,
  party_id                  integer
                            constraint wf_case_actn_asgn_party_id_fk
                            references parties(party_id)
                            on delete cascade,
  constraint wf_case_action_assignees_pk
  primary key (enabled_action_id, party_id)
);

create index wf_case_actn_asgn_en_act_idx on workflow_case_action_assignees(enabled_action_id);
create index wf_case_actn_asgn_party_idx on workflow_case_action_assignees(party_id);

---------------------------------
-- Deputies
---------------------------------

-- When a user is away, for example on vacation, he
-- can hand over his workflow roles to some other user - a deputy
create table workflow_deputies (
  -- user_id is the user that has a deputy, on whose behalf the deputy will operate
  user_id             integer
		      constraint workflow_deputies_pk
		      primary key
		      constraint workflow_deputies_uid_fk
		      references users(user_id),
  -- deputy_user_id is the user taking over the other user's tasks
  deputy_user_id      integer
		      constraint workflow_deputies_duid_fk
		      references users(user_id),
  start_date	      timestamptz
		      constraint workflow_deputies_sdate_nn
		      not null,
  end_date	      timestamptz
		      constraint workflow_deputies_edate_nn
		      not null,
  message	      varchar(4000)
);

create index workflow_deputies_deputy_idx on workflow_deputies(deputy_user_id);
create index workflow_deputies_start_date_idx on workflow_deputies(start_date);
create index workflow_deputies_end_date_idx on workflow_deputies(end_date);


---------------------------------
-- Case level, Finite State Machine Model
---------------------------------

create table workflow_case_fsm (
  case_id                   integer
                            constraint wf_case_fsm_case_id_nn
                            not null
                            constraint wf_case_fsm_case_id_fk
                            references workflow_cases(case_id)
                            on delete cascade,
  parent_enabled_action_id  integer
                            constraint wf_case_fsm_action_id_fk
                            references workflow_case_enabled_actions(enabled_action_id)
                            on delete cascade,
  current_state             integer
                            constraint wf_case_fsm_st_id_fk
                            references workflow_fsm_states(state_id)
                            on delete cascade,
  constraint wf_case_fsm_case_parent_un
  unique (case_id, parent_enabled_action_id)
);

create index wf_case_fsm_prnt_enbl_actn_idx on workflow_case_fsm(parent_enabled_action_id);
create index wf_case_fsm_state_idx on workflow_case_fsm(current_state);

---------------------------------
-- Case level, Activity Log
---------------------------------

create table workflow_case_log (
  entry_id                integer
                          constraint wf_case_log_pk
                          primary key
                          constraint wf_case_log_cr_items_fk 
                          references cr_items(item_id),
  case_id                 integer
                          constraint wf_case_log_case_id_fk 
                          references workflow_cases(case_id)
                          on delete cascade,
  action_id               integer
                          constraint wf_case_log_acn_id_fk
                          references workflow_actions(action_id)
                          on delete cascade
);

create index workflow_case_log_action_id on workflow_case_log (action_id);
create index workflow_case_log_case_id on workflow_case_log (case_id);


create table workflow_case_log_data (
  entry_id                integer
                          constraint wf_case_log_data_eid_nn
                          not null
                          constraint wf_case_log_data_eid_fk
                          references workflow_case_log(entry_id)
                          on delete cascade,
  key                     varchar(50),
  value                   varchar(4000),
  constraint wf_case_log_data_pk
  primary key (entry_id, key)
);

select content_type__create_type (
  'workflow_case_log_entry',         -- content_type
  'content_revision',                -- supertype
  'Workflow Case Log Entry',         -- pretty_name
  'Workflow Case Log Entries',       -- pretty_plural
  'workflow_case_log_rev',           -- table_name
  'entry_rev_id',                    -- id_column
  null                               -- name_method
);

-----------------
-- Useful views
-----------------

-- Answers the question: Who is this user acting on behalf of? Which user is allowed to act on behalf of me?
-- A mapping between users and their deputies
create or replace view workflow_user_deputy_map as
    select coalesce(dep.deputy_user_id, u.user_id) as user_id,
           u.user_id as on_behalf_of_user_id
    from   users u left outer join
           workflow_deputies dep on (dep.user_id = u.user_id and current_timestamp between start_date and end_date);

-- Answers the question: What are the enabled and assigned actions and which role are they assigned to?
-- Useful for showing the task list for a particular user or role.
-- Note that dynamic actions can very well be assigned even though they don't have an assigned_role;
-- the assignees will be in workflow_case_action_assignees.
create or replace view workflow_case_assigned_actions as
    select c.workflow_id,
           wcea.case_id,
           c.object_id,
           wcea.action_id,
           wa.assigned_role as role_id,
           wcea.enabled_action_id
      from workflow_case_enabled_actions wcea,
           workflow_actions wa,
           workflow_cases c
     where wcea.completed_p = 'f'
       and wcea.assigned_p = 't'
       and wa.action_id = wcea.action_id
       and c.case_id = wcea.case_id;

-- This view specifically answers the question: What are the actions assigned to this user?

-- Answers the question: Which parties are currently assigned to which actions?
-- Does not take deputies into account.
-- Pimarily needed for building the wf_case_assigned_user_actions view.
-- TODO: See if we can find a way to improve this without the union?
create or replace view wf_case_assigned_party_actions as
    select wcaa.enabled_action_id,
           wcaa.action_id,
           wcaa.case_id,
           wcaasgn.party_id
    from   workflow_case_assigned_actions wcaa,
           workflow_case_action_assignees wcaasgn
    where  wcaasgn.enabled_action_id = wcaa.enabled_action_id
    union
    select wcaa.enabled_action_id,
           wcaa.action_id,
           wcaa.case_id,
           wcrpm.party_id
    from   workflow_case_assigned_actions wcaa,
           workflow_case_role_party_map wcrpm
    where  wcrpm.role_id = wcaa.role_id
    and    wcrpm.case_id = wcaa.case_id
    and    not exists (select 1 
                       from   workflow_case_action_assignees 
                       where  enabled_action_id = wcaa.enabled_action_id);
-- TODO: Above 'not exists' can be removed, if we store the assigned_role_id with the 
-- workflow_case_enabled_actions table,
-- and set it to null when assignment is dynamic like here


-- Answers the question: which actions is this user assigned to?
-- Does take deputies into account
create or replace view wf_case_assigned_user_actions as
    select wcapa.enabled_action_id,
           wcapa.action_id,
           wcapa.case_id,
           wudm.user_id,
           wudm.on_behalf_of_user_id
    from   wf_case_assigned_party_actions wcapa,
           party_approved_member_map pamm,
           workflow_user_deputy_map wudm
    where  pamm.party_id = wcapa.party_id
    and    wudm.on_behalf_of_user_id = pamm.member_id;

-- Answers the question: which roles is this user playing?
-- Does take deputies into account
create or replace view workflow_case_role_user_map as
    select wcrpm.case_id,
           wcrpm.role_id,
           wudm.user_id,
           wudm.on_behalf_of_user_id
    from   workflow_case_role_party_map wcrpm,
           party_approved_member_map pamm,
           workflow_user_deputy_map wudm
    where  pamm.party_id = wcrpm.party_id
    and    wudm.on_behalf_of_user_id = pamm.member_id;
