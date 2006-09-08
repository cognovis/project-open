
-- Add URLs for object type "Timesheet Task"

insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','view','/intranet/projects/view?project_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_task','edit','/intranet/projects/new?project_id=');


-- Counter without number restriction
--
create or replace function im_day_enumerator (
        date, date
) returns setof date as '
declare
        p_start_date            alias for $1;
        p_end_date              alias for $2;
        v_date                  date;
BEGIN
        v_date := p_start_date;
        WHILE (v_date < p_end_date) LOOP
                RETURN NEXT v_date;
                v_date := v_date + 1;
        END LOOP;
        RETURN;
end;' language 'plpgsql';



