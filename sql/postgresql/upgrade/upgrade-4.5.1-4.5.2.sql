-- upgrade-4.5.1-4.5.2.sql

-- Add a new "object_type" field per workflow in order
-- to define the type of object that this WF is about

alter table wf_workflows
add object_type varchar(100)
constraint wf_workflows_otype_fk
references acs_object_types;



