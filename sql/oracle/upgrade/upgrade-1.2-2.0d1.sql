--
-- Adding hierarchy, parallelism and timed actions
-- 
-- @cvs-id $Id$
--

----------------------------------------------------------------------
-- Fixing various problems and omissions with the old data model
----------------------------------------------------------------------

-- Missing unique constraints on names
-- TODO: Test these
alter table workflow_roles add constraint wf_roles_short_name_un unique (workflow_id, short_name);
alter table workflow_roles add constraint wf_roles_pretty_name_un unique (workflow_id, pretty_name);

alter table workflow_actions add constraint wf_actions_short_name_un unique (workflow_id, short_name);
alter table workflow_actions add constraint wf_actions_pretty_name_un unique (workflow_id, pretty_name);

alter table workflow_fsm_states add constraint wf_fsm_states_short_name_un unique (workflow_id, short_name);
alter table workflow_fsm_states add constraint wf_fsm_states_pretty_name_un unique (workflow_id, pretty_name);

-- Not bothering with the not null constraints for workflow_initial_action as we're dropping that table anyway

-- Changing from 'on delete cascade' to 'on delete set null'
alter table workflow_fsm_actions drop constraint wf_fsm_acns_new_st_fk;
alter table workflow_fsm_actions add 
    constraint wf_fsm_acns_new_st_fk foreign key (new_state)
    references workflow_fsm_states(state_id) on delete set null;

-- Adding unique constraint on workflow fsm enabled in actions
-- This could cause upgrades to fail, if there are in fact duplicates, so let's pray that there aren't
alter table workflow_fsm_action_en_in_st add constraint workflow_fsm_acn_en_in_st_pk primary key (action_id, state_id);

-- adding user_id and start/end date indices
create index workflow_deputies_deputy_idx on workflow_deputies(deputy_user_id);
create index workflow_deputies_sd_idx on workflow_deputies(start_date);
create index workflow_deputies_ed_idx on workflow_deputies(end_date);

-- TODO: This isn't strictly required, but might be useful, anyhow
-- object_id can now be null, and doesn't have to be unique 
-- (since we're going to have plenty of rows with null object_id)
alter table workflow_cases drop constraint wf_cases_object_id_un;
alter table workflow_cases drop constraint wf_cases_object_id_nn;

-- Adding foreign key index on workflow_fsm_states
create index wf_fsm_states_workflow_idx on workflow_fsm_states(workflow_id);

-- Changing referential integrity constraint on workflow_fsm_action_en_in_st
alter table workflow_fsm_action_en_in_st drop constraint wf_fsm_acn_enb_in_st_acn_id_fk;
alter table workflow_fsm_action_en_in_st add foreign key (action_id) references workflow_actions(action_id) on delete cascade;

-- Missing cascading delete indices
create index wf_fsm_act_en_in_st_action_idx on workflow_fsm_action_en_in_st(action_id);
create index wf_fsm_act_en_in_st_state_idx on workflow_fsm_action_en_in_st(state_id);

----------------------------------------------------------------------
-- Adding hierarchy and parallelism
----------------------------------------------------------------------

-- Adding hierarchical actions
alter table workflow_actions add
  parent_action_id          integer
                            constraint wf_acns_parent_action_fk
                            references workflow_actions(action_id)
                            on delete cascade;

-- Adding explicit trigger_type, for use with hierarchy and parallelism; replacing workflow_initial_action table
alter table workflow_actions add
  trigger_type              varchar(50) default 'user'
                            constraint wf_acns_trigger_type_ck
                            check (trigger_type in ('user','auto','init','time','message','parallel','workflow','dynamic'));
update workflow_actions set trigger_type = 'user';
update workflow_actions
set    trigger_type = 'init'
where  action_id in (select action_id 
                     from   workflow_initial_action);
drop table workflow_initial_action;

-- Adding timeout for timed actions
alter table workflow_actions add timeout_seconds integer;

-- Add parent_action_id to states table
alter table workflow_fsm_states add 
  parent_action_id          integer
                            constraint wf_fsm_states_parent_action_fk
                            references workflow_actions(action_id)
                            on delete cascade;
create index wf_fsm_states_prnt_action_idx on workflow_fsm_states(parent_action_id);

-- Adding enabled actions table to hold dynamic/parallel actions
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
  assigned_p                char(1) default 'f'
                            constraint wf_case_enbl_act_ap_ck
                            check (assigned_p in ('t', 'f')),
  completed_p               char(1) default 'f'
                            constraint wf_case_enbl_act_cp_ck
                            check (completed_p in ('t', 'f')),
  execution_time            date
);

create index wf_case_enbl_act_case_idx on workflow_case_enabled_actions(case_id);
create index wf_case_enbl_act_action_idx on workflow_case_enabled_actions(action_id);

-- Adding enabled action assignees table for dynamic actions
create table workflow_case_action_assignees(
  enabled_action_id         integer
                            constraint wf_case_actn_asgn_eaid_fk
                            references workflow_case_enabled_actions
                            on delete cascade,
  party_id                  integer
                            constraint wf_case_actn_asgn_pid_fk
                            references parties(party_id)
                            on delete cascade,
  constraint wf_case_action_assignees_pk
  primary key (enabled_action_id, party_id)
);

create index wf_case_actn_asgn_en_act_idx on workflow_case_action_assignees(enabled_action_id);
create index wf_case_actn_asgn_party_idx on workflow_case_action_assignees(party_id);

-- A case now has multiple states, but only one per parent_action_id
alter table workflow_case_fsm add
  parent_enabled_action_id  integer
                            constraint wf_case_fsm_action_id_fk
                            references workflow_case_enabled_actions(enabled_action_id)
                            on delete cascade;

alter table workflow_case_fsm add
  constraint wf_case_fsm_case_parent_un
  unique (case_id, parent_enabled_action_id);

create index wf_case_fsm_prnt_enbl_actn_idx on workflow_case_fsm(parent_enabled_action_id);
create index workflow_case_fsm_state_idx on workflow_case_fsm(current_state);

-- New and changed views

-- Answers the question: Who is this user acting on behalf of? Which user is allowed to act on behalf of me?
-- A mapping between users and their deputies
create or replace view workflow_user_deputy_map as
    select nvl(dep.deputy_user_id, u.user_id) as user_id,
           u.user_id as on_behalf_of_user_id
    from   users u,
           workflow_deputies dep
    where  u.user_id = dep.user_id (+)
      and  ((dep.start_date is null and dep.end_date is null) or
             (sysdate between dep.start_date and  dep.end_date)
           );

-- Answers the question: What are the enabled and assigned actions and which role are they assigned to?
-- Useful for showing the task list for a particular user or role.
-- Note that dynamic actions can very well be assigned even though they don't have an assigned_role;
-- the assignees will be in workflow_case_action_assignees.
drop view workflow_case_assigned_actions;
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

-- pretty-name unique per parent, not per workflow
alter table workflow_actions 
  drop constraint wf_actions_pretty_name_un;
alter table workflow_actions 
  add constraint wf_actions_pretty_name_un
  unique (workflow_id, parent_action_id, pretty_name);

alter table workflow_fsm_states
  drop constraint wf_fsm_states_pretty_name_un;
alter table workflow_fsm_states
  add constraint wf_fsm_states_pretty_name_un
  unique (workflow_id, parent_action_id, pretty_name);
