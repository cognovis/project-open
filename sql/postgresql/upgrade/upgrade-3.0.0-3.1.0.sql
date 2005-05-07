--
-- upgrade-3.0.0-3.1.0.sql

alter table im_hours add
        material_id             integer
                                constraint im_hours_material_fk
                                references im_materials
;