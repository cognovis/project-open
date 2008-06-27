-- upgrade-3.3.1.0.0-3.3.1.1.0.sql


-- Allow translation tasks to be checked/unchecked all together

delete from im_view_columns where column_id = 9021;

insert into im_view_columns (
        column_id, view_id, group_id, column_name,
        column_render_tcl, extra_select, extra_where,
        sort_order, visible_for
) values (
        9021,90,NULL,
        '<input type=checkbox name=_dummy onclick=\\"acs_ListCheckAll(''task'',this.checked)\\">',
        '$del_checkbox','','',
        21,'expr $project_write'
);


-- Add a new column to im_task_actions to record the file
-- that the translator has actually uploaded.
--
alter table im_task_actions add column upload_file varchar(1000);



-- insert into im_view_columns (
--      column_id, view_id, group_id, column_name,
--      column_render_tcl, extra_select, extra_where,
--      sort_order, visible_for
-- ) values (
--      9021,90,NULL,'[im_gif delete "Delete the Task"]',
--      '$del_checkbox','','',
--      21,'expr $project_write'
-- );



-- ------------------------------------------------------------
-- Return a list of target languages for a project
-- ------------------------------------------------------------

create or replace function im_trans_project_target_languages (integer)
returns varchar as '
DECLARE
        p_project_id            alias for $1;

        row                     RECORD;
        v_result                varchar;
BEGIN
    v_result := '''';

    FOR row IN
        select  tl.*,
                im_category_from_id(tl.language_id) as language
        from    im_target_languages tl
        where   tl.project_id = p_project_id
    LOOP
        IF '''' != v_result THEN v_result := v_result || '', ''; END IF;
        v_result := v_result || row.language;
    END LOOP;

    return v_result;
end;' language 'plpgsql';

