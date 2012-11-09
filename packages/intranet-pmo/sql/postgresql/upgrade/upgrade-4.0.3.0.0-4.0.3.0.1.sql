-- upgrade-4.0.3.0.0-4.0.3.0.1.sql
SELECT acs_log__debug('/packages/intranet-pmo/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');

create table im_project_assignments (
       user_id integer constraint user_id_fk references users(user_id) on delete cascade not null,
       project_id integer constraint project_id_fk references im_projects(project_id) on delete cascade not null,
       rel_id integer constraint rel_id_fk references im_biz_object_members(rel_id) on delete set null,
       start_date date not null,
       availability float default 100,
       primary key(user_id,project_id,start_date)
);
