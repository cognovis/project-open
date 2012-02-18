-- upgrade-0.1d-0.1d2.sql

create table views_by_type (
        object_id       integer
                        constraint views_by_type_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint views_by_type_object_id_nn
                        not null,
        viewer_id       integer
                        constraint views_by_type_owner_id_fk
                        references parties(party_id) on delete cascade
                        constraint views_by_type_viewer_id_nn
                        not null,
        type            varchar(100) not null,
        views           integer default 1,
        last_viewed     timestamptz default now(),
        constraint views_by_type_pk 
        primary key (object_id, viewer_id, type)
);

create unique index views_by_type_viewer_idx on views_by_type(viewer_id, object_id, type);

comment on table views_by_type is '
        a simple count of how many times an object is viewed for each type.
';

create table view_aggregates_by_type (
        object_id       integer
                        constraint view_aggregates_by_type_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint view_aggregates_by_type_object_id_nn
                        not null,
        type            varchar(100) not null,
        views           integer default 1,
        unique_views    integer default 1,
        last_viewed     timestamptz default now(),
        constraint view_aggregates_by_type_pk
        primary key (object_id, type)
);

comment on table view_aggregates_by_type is '
        a simple count of how many times an object is viewed for each type,
        multiple visits trigger maintained by updates on views_by_type.
';


create or replace function views_by_type__record_view (integer, integer, varchar) returns integer as '
declare
    p_object_id alias for $1;
    p_viewer_id alias for $2;
    p_type      alias for $3;
    v_views    views.views%TYPE;
begin 
    select views into v_views from views_by_type where object_id = p_object_id and viewer_id = p_viewer_id and type = p_type;

    if v_views is null then 
        INSERT into views_by_type(object_id,viewer_id,type) 
        VALUES (p_object_id, p_viewer_id,p_type);
        v_views := 0;
    else
        UPDATE views_by_type
           SET views = views + 1, last_viewed = now(), type = p_type
         WHERE object_id = p_object_id
           and viewer_id = p_viewer_id
           and type = p_type;
    end if;

    return v_views + 1;
end;' language 'plpgsql';

comment on function views_by_type__record_view(integer, integer, varchar) is 'update the view by type count of object_id for viewer viewer_id, returns view count';

select define_function_args('views_by_type__record_view','object_id,viewer_id,type');

create function views_by_type_ins_tr () returns opaque as '
begin
    if not exists (select 1 from view_aggregates_by_type where object_id = new.object_id and type = new.type) then 
        INSERT INTO view_aggregates_by_type (object_id,type,views,unique_views,last_viewed) 
        VALUES (new.object_id,new.type,1,1,now());
    else
        UPDATE view_aggregates_by_type
           SET views = views + 1, unique_views = unique_views + 1, last_viewed = now() 
         WHERE object_id = new.object_id
           AND type = new.type;
    end if;

    return new;
end;' language 'plpgsql';

create trigger views_by_type_ins_tr 
after insert on views_by_type
for each row
execute procedure views_by_type_ins_tr();

create function views_by_type_upd_tr () returns opaque as '
begin
    UPDATE view_aggregates_by_type 
       SET views = views + 1, last_viewed = now() 
     WHERE object_id = new.object_id
       AND type = new.type;

    return new;
end;' language 'plpgsql';

create trigger views_by_type_upd_tr
after update on views_by_type
for each row
execute procedure views_by_type_upd_tr();

