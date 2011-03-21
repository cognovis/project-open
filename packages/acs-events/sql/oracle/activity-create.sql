-- packages/acs-events/sql/activity-create.sql
--
-- @author W. Scott Meeks
-- @author Gary Jin (gjin@arsdigita.com)
-- $Id: activity-create.sql,v 1.6 2004/03/12 18:48:48 jeffd Exp $
--
-- The activity object

begin
    acs_object_type.create_type ( 
    supertype     => 'acs_object', 
    object_type   => 'acs_activity', 
    pretty_name   => 'Activity', 
    pretty_plural => 'Activities', 
    table_name    => 'ACS_ACTIVITIES', 
    id_column     => 'ACTIVITY_ID' 
  ); 
end;
/
show errors

declare 
    attr_id acs_attributes.attribute_id%TYPE; 
begin
    attr_id := acs_attribute.create_attribute ( 
         object_type    => 'acs_activity', 
         attribute_name => 'name', 
         pretty_name    => 'Name', 
         pretty_plural  => 'Names', 
         datatype       => 'string' 
    ); 

    attr_id := acs_attribute.create_attribute ( 
         object_type    => 'acs_activity', 
         attribute_name => 'description', 
         pretty_name    => 'Description', 
         pretty_plural  => 'Descriptions', 
         datatype       => 'string' 
    ); 

    attr_id := acs_attribute.create_attribute ( 
         object_type    => 'acs_activity', 
         attribute_name => 'html_p', 
         pretty_name    => 'HTML?', 
         pretty_plural  => 'HTML?', 
         datatype       => 'string' 
    ); 

    attr_id := acs_attribute.create_attribute ( 
         object_type    => 'acs_activity', 
         attribute_name => 'status_summary', 
         pretty_name    => 'Status Summary', 
         pretty_plural  => 'Status Summaries', 
         datatype       => 'string' 
    ); 
end;
/
show errors

-- The activities table

create table acs_activities (
    activity_id         integer
                        constraint acs_activities_fk
                        references acs_objects(object_id)
                        on delete cascade
                        constraint acs_activities_pk
                        primary key,
    name                varchar2(255) not null,
    description         varchar2(4000),
    -- is the activity description written in html?
    html_p              char(1) 
                        constraint acs_activities_html_p_ck
                        check(html_p in ('t','f')),
    status_summary      varchar2(255)
);

comment on table acs_activities is '
    Represents what happens during an event
';
        
create table acs_activity_object_map (
    activity_id         integer
                        constraint acs_act_obj_mp_activity_id_fk
                        references acs_activities on delete cascade,
    object_id           integer
                        constraint acs_act_obj_mp_object_id_fk
                        references acs_objects(object_id) on delete cascade,
    constraint acs_act_obj_mp_pk
    primary key(activity_id, object_id)
);

comment on table acs_activity_object_map is '
    Maps between an activity and multiple ACS objects.
';

create or replace package acs_activity
as
    function new ( 
         -- Create a new activity
         -- @author W. Scott Meeks
         -- @param activity_id       optional id to use for new activity
         -- @param name                         Name of the activity 
         -- @param description          optional description of the activity
         -- @param html_p               optional description is html
         -- @param status_summary       optional additional status to display
         -- @param object_type          'acs_activity'
         -- @param creation_date        default sysdate
         -- @param creation_user        acs_object param
         -- @param creation_ip          acs_object param
         -- @param context_id           acs_object param
         -- @return The id of the new activity.
         --
         activity_id         in acs_activities.activity_id%TYPE   default null, 
         name                in acs_activities.name%TYPE,
         description         in acs_activities.description%TYPE   default null,
         html_p              in acs_activities.html_p%TYPE        default 'f',
         status_summary      in acs_activities.status_summary%TYPE        default null,
         object_type         in acs_object_types.object_type%TYPE default 'acs_activity', 
         creation_date       in acs_objects.creation_date%TYPE    default sysdate, 
         creation_user       in acs_objects.creation_user%TYPE    default null, 
         creation_ip         in acs_objects.creation_ip%TYPE      default null, 
         context_id          in acs_objects.context_id%TYPE       default null 
    ) return acs_activities.activity_id%TYPE; 

    function name (
        -- name method
        -- @author gjin@arsdigita.com
        -- @param activity_id
        --
        activity_id          in acs_activities.activity_id%TYPE
        
    ) return acs_activities.name%TYPE;
 
    procedure del ( 
         -- Deletes an activity
         -- @author W. Scott Meeks
         -- @param activity_id      id of activity to delete
         activity_id      in acs_activities.activity_id%TYPE 
    ); 


    -- NOTE: can't use update

    procedure edit (
         -- Update the name or description of an activity
         -- @author W. Scott Meeks
         -- @param activity_id activity to update
         -- @param name        optional New name for this activity
         -- @param description optional New description for this activity
         -- @param html_p      optional New value of html_p for this activity
         activity_id         in acs_activities.activity_id%TYPE, 
         name                in acs_activities.name%TYPE default null,
         description         in acs_activities.description%TYPE default null,
         html_p              in acs_activities.html_p%TYPE default null,
         status_summary      in acs_activities.status_summary%TYPE default null
    );

    procedure object_map (
         -- Adds an object mapping to an activity
         -- @author W. Scott Meeks
         -- @param activity_id       id of activity to add mapping to
         -- @param object_id         id of object to add mapping for
         --
         activity_id         in acs_activities.activity_id%TYPE, 
         object_id           in acs_objects.object_id%TYPE
    );

    procedure object_unmap (
         -- Deletes an object mapping from an activity
         -- @author W. Scott Meeks
         -- @param activity_id activity to delete mapping from
         -- @param object_id   object to delete mapping for
         --
         activity_id         in acs_activities.activity_id%TYPE, 
         object_id           in acs_objects.object_id%TYPE
    );

end acs_activity;
/
show errors

create or replace package body acs_activity
as
    function new ( 
         activity_id         in acs_activities.activity_id%TYPE   default null, 
         name                in acs_activities.name%TYPE,
         description         in acs_activities.description%TYPE   default null,
         html_p              in acs_activities.html_p%TYPE        default 'f',
         status_summary      in acs_activities.status_summary%TYPE  default null,
         object_type         in acs_object_types.object_type%TYPE default 'acs_activity', 
         creation_date       in acs_objects.creation_date%TYPE    default sysdate, 
         creation_user       in acs_objects.creation_user%TYPE    default null, 
         creation_ip         in acs_objects.creation_ip%TYPE      default null, 
         context_id          in acs_objects.context_id%TYPE       default null 
    ) return acs_activities.activity_id%TYPE
    is
        new_activity_id acs_activities.activity_id%TYPE;
    begin
        new_activity_id := acs_object.new(
            object_id     => activity_id,
            object_type   => object_type,
            title         => name,
            creation_date => creation_date,
            creation_user => creation_user,
            creation_ip   => creation_ip,
            context_id    => context_id
        );

        insert into acs_activities
            (activity_id, name, description, html_p, status_summary)
        values
            (new_activity_id, name, description, html_p, status_summary);

        return new_activity_id;
    end new;


    function name (
        -- name method
        -- @author gjin@arsdigita.com
        -- @param activity_id
        --
        activity_id          in acs_activities.activity_id%TYPE
        
    ) return acs_activities.name%TYPE
        
    is
        new_activity_name    acs_activities.name%TYPE;

    begin
        select  name
        into    new_activity_name
        from    acs_activities
        where   activity_id = name.activity_id;

        return  new_activity_name;
    end;

         
    procedure del ( 
         activity_id in acs_activities.activity_id%TYPE 
    )
    is
    begin
         -- Cascade will cause delete from acs_activities 
         -- and acs_activity_object_map

         acs_object.del(activity_id); 
    end del;

    -- NOTE: can't use update

    procedure edit (
         activity_id     in acs_activities.activity_id%TYPE, 
         name            in acs_activities.name%TYPE default null,
         description     in acs_activities.description%TYPE default null,
         html_p          in acs_activities.html_p%TYPE default null,
         status_summary  in acs_activities.status_summary%TYPE default null
    )
    is
    begin
        update acs_activities
        set    name        = nvl(edit.name, name),
               description = nvl(edit.description, description),
               html_p      = nvl(edit.html_p, html_p),
               status_summary = nvl(edit.status_summary, status_summary)
        where activity_id  = edit.activity_id;

        update acs_objects
        set    title = nvl(edit.name, title)
        where object_id = edit.activity_id;
    end edit;

    procedure object_map (
        activity_id in acs_activities.activity_id%TYPE, 
        object_id   in acs_objects.object_id%TYPE
    )
    is
    begin
        insert into acs_activity_object_map
            (activity_id, object_id)
        values
            (activity_id, object_id);
    end object_map;

    procedure object_unmap (
        activity_id in acs_activities.activity_id%TYPE, 
         object_id  in acs_objects.object_id%TYPE
    )
    is
    begin
        delete from acs_activity_object_map
        where  activity_id = object_unmap.activity_id
        and    object_id   = object_unmap.object_id;
    end object_unmap;

end acs_activity;
/
show errors





