-- Views
--
-- Tracking and aggregating object views...
--
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis <davis@xarg.net>
-- @creation-date 1/12/2003
--
-- @cvs-id $Id: views-datamodel.sql,v 1.3 2007/08/01 08:59:56 marioa Exp $
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create table views_views (
        object_id       integer
                        constraint views_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint views_object_id_nn
                        not null,
        viewer_id       integer
                        constraint views_owner_id_fk
                        references parties(party_id) on delete cascade
                        constraint views_viewer_id_nn
                        not null,
        views_count     integer default 1,
        last_viewed     timestamptz default now(),
        constraint views_views_pk 
        primary key (object_id, viewer_id)
);

create unique index views_views_viewer_idx on views_views(viewer_id, object_id);

comment on table views_views is '
        a simple count of how many times an object is viewed.
';

create table view_aggregates (
        object_id       integer
                        constraint view_aggs_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint view_aggs_object_id_nn
                        not null 
                        constraint view_aggregatess_pk 
                        primary key,
        views_count     integer default 1,
        unique_views    integer default 1,
        last_viewed     timestamptz default now()
);

comment on table view_aggregates is '
        a simple count of how many times an object is viewed, multiple visits
        trigger maintained by updates on views.
';

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
        view_type       varchar(100) not null,
        views_count     integer default 1,
        last_viewed     timestamptz default now(),
        constraint views_by_type_pk 
        primary key (object_id, viewer_id, view_type)
);

create unique index views_by_type_viewer_idx on views_by_type(viewer_id, object_id, view_type);

comment on table views_by_type is '
        a simple count of how many times an object is viewed for each type.
';

create table view_aggregates_by_type (
        object_id       integer
                        constraint view_agg_b_type_ob_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint view_agg_b_type_ob_id_nn
                        not null,
        view_type            varchar(100) not null,
        views_count     integer default 1,
        unique_views    integer default 1,
        last_viewed     timestamptz default now(),
        constraint view_aggregates_by_type_pk
        primary key (object_id, view_type)
);

comment on table view_aggregates_by_type is '
        a simple count of how many times an object is viewed for each type,
        multiple visits trigger maintained by updates on views_by_type.
';

