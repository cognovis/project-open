--
-- upgrade-3.0.0-3.1.0.sql

alter table im_hours add
        material_id             integer
                                constraint im_hours_material_fk
                                references im_materials
;


-- specified how many units of what material are planned for
-- each project / subproject / task (all the same...)
--
create table im_timesheet_tasks (
        project_id              integer not null
                                constraint im_timesheet_tasks_project_fk
                                references im_projects,
        material_id             integer
                                constraint im_timesheet_tasks_material_fk
                                references im_materials,
        uom_id                  integer
                                constraint im_timesheet_tasks_uom_fk
                                references im_categories,
        planned_units           float,
        billable_units          float,
                                -- sum of timesheet hours cached here for
                                -- easier reporting.
        reported_units_cache    float,
        description             varchar(4000),
        primary key(project_id, material_id)
);
