-- packages/views/sql/postgresql/upgrade/upgrade-0.1d2-0.1d3.sql
--
-- Upgrade tables names and column to Oracle compatibility
--
-- Copyright (C) 2006 Innova - UNED
-- @author Mario Aguado <maguado@innova.uned.es>
-- @creation-date 20/07/2006
--
-- @cvs-id $Id: upgrade-0.1d2-0.1d3.sql,v 1.1 2007/08/01 08:59:57 marioa Exp $
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

--Drop function triggers

drop function views_upd_tr() cascade;
drop function views_ins_tr() cascade;
drop function views_by_type_ins_tr() cascade;
drop function views_by_type_upd_tr() cascade;

--Rename table and column name

alter table views rename column views to views_count;
alter table view_aggregates rename column views to views_count;
alter table views rename to views_views;
alter index views_viewer_idx rename to views_views_viewer_idx;

alter table views_by_type rename column views to views_count;
alter table view_aggregates_by_type rename column views to views_count;

alter table views_by_type rename column type to view_type;
alter table view_aggregates_by_type rename column type to view_type;

--Modify function with new table and column names.

create or replace function views__record_view (integer, integer) returns integer as '
declare
    p_object_id alias for $1;
    p_viewer_id alias for $2;
    v_views    views_views.views_count%TYPE;
begin 
    select views_count into v_views from views_views where object_id = p_object_id and viewer_id = p_viewer_id;

    if v_views is null then 
        INSERT into views_views(object_id,viewer_id) 
        VALUES (p_object_id, p_viewer_id);
        v_views := 0;
    else
        UPDATE views_views
           SET views_count = views_count + 1, last_viewed = now()
         WHERE object_id = p_object_id
           and viewer_id = p_viewer_id;
    end if;

    return v_views + 1;
end;' language 'plpgsql';

--Create new triggers with new names

create or replace function views_views_ins_tr () returns opaque as '
begin
    if not exists (select 1 from view_aggregates where object_id = new.object_id) then 
        INSERT  INTO view_aggregates (object_id,views_count,unique_views,last_viewed) 
        VALUES (new.object_id,1,1,now());
    else
        UPDATE view_aggregates 
           SET views_count = views_count + 1, unique_views = unique_views + 1, last_viewed = now() 
         WHERE object_id = new.object_id;
    end if;

    return new;
end;' language 'plpgsql';

create trigger views_views_ins_tr 
after insert on views_views
for each row
execute procedure views_views_ins_tr();

create or replace function views_views_upd_tr () returns opaque as '
begin
    UPDATE view_aggregates 
       SET views_count = views_count + 1, last_viewed = now() 
     WHERE object_id = new.object_id;

    return new;
end;' language 'plpgsql';

create trigger views_views_upd_tr
after update on views_views
for each row
execute procedure views_views_upd_tr();


create or replace function views_by_type__record_view (integer, integer, varchar) returns integer as '
declare
    p_object_id alias for $1;
    p_viewer_id alias for $2;
    p_view_type      alias for $3;
    v_views     views_views.views_count%TYPE;
begin 
    select views_count into v_views from views_by_type where object_id = p_object_id and viewer_id = p_viewer_id and view_type = p_view_type;

    if v_views is null then 
        INSERT into views_by_type(object_id,viewer_id,view_type) 
        VALUES (p_object_id, p_viewer_id,p_view_type);
        v_views := 0;
    else
        UPDATE views_by_type
           SET views_count = views_count + 1, last_viewed = now(), view_type = p_view_type
         WHERE object_id = p_object_id
           and viewer_id = p_viewer_id
           and view_type = p_view_type;
    end if;

    return v_views + 1;
end;' language 'plpgsql';

comment on function views_by_type__record_view(integer, integer, varchar) is 'update the view by type count of object_id for viewer viewer_id, returns view count';

select define_function_args('views_by_type__record_view','object_id,viewer_id,view_type');

create or replace function views_by_type_ins_tr () returns opaque as '
begin
    if not exists (select 1 from view_aggregates_by_type where object_id = new.object_id and view_type = new.view_type) then 
        INSERT INTO view_aggregates_by_type (object_id,view_type,views_count,unique_views,last_viewed) 
        VALUES (new.object_id,new.view_type,1,1,now());
    else
        UPDATE view_aggregates_by_type
           SET views_count = views_count + 1, unique_views = unique_views + 1, last_viewed = now() 
         WHERE object_id = new.object_id
           AND view_type = new.view_type;
    end if;

    return new;
end;' language 'plpgsql';

create trigger views_by_type_ins_tr 
after insert on views_by_type
for each row
execute procedure views_by_type_ins_tr();

create or replace function views_by_type_upd_tr () returns opaque as '
begin
    UPDATE view_aggregates_by_type 
       SET views_count = views_count + 1, last_viewed = now() 
     WHERE object_id = new.object_id
       AND view_type = new.view_type;

    return new;
end;' language 'plpgsql';

create trigger views_by_type_upd_tr
after update on views_by_type
for each row
execute procedure views_by_type_upd_tr();
