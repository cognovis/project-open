--
-- Added assignee and fix for version to the bug add form
--
-- 
--
-- @cvs-id $Id$
--

create or replace package bt_bug
as
    function new (
        bug_id          in integer default null,
        bug_number      in integer default null,
        package_id      in integer,
        component_id    in integer,
        found_in_version in integer,
        summary         in varchar2,
        user_agent      in varchar2 default null,
        comment_content in varchar2,
        comment_format  in varchar2,
        creation_date   in date default sysdate(),
        creation_user   in integer,
        creation_ip     in varchar2 default null,
	fix_for_version in integer default null,
        item_subtype    in varchar2 default 'bt_bug',
        content_type    in varchar2 default 'bt_bug_revision'
    ) return integer;

    procedure del (
        bug_id          in integer
    );

    function name (
        bug_id        in integer
    ) return varchar2;

end bt_bug;
/
show errors


create or replace package body bt_bug
as
    function new (
        bug_id          in integer default null,
        bug_number      in integer default null,
        package_id      in integer,
        component_id    in integer,
        found_in_version in integer,
        summary         in varchar2,
        user_agent      in varchar2 default null,
        comment_content in varchar2,
        comment_format  in varchar2,
        creation_date   in date default sysdate(),
        creation_user   in integer,
        creation_ip     in varchar2 default null,
	fix_for_version in integer default null,
        item_subtype    in varchar2 default 'bt_bug',
        content_type    in varchar2 default 'bt_bug_revision'
    ) return integer
    is
        v_bug_id        integer;
        v_revision_id   integer;
        v_bug_number    integer;
        v_folder_id     integer;
    begin
        -- get the content folder for this instance
        select folder_id
        into   v_folder_id
        from   bt_projects
        where  project_id = bt_bug.new.package_id;

        -- get bug_number
        if bug_number is null then
          select nvl(max(bug_number),0) + 1
          into   v_bug_number
          from   bt_bugs
          where  parent_id = v_folder_id;
        else
          v_bug_number := bug_number;
        end if;

        -- create the content item
        v_bug_id := content_item.new(
            name =>             v_bug_number, 
            parent_id =>        v_folder_id,   
            item_id =>          bt_bug.new.bug_id,       
            locale =>           null,            
            creation_date =>    bt_bug.new.creation_date,  
            creation_user =>    bt_bug.new.creation_user,  
            context_id =>       v_folder_id,      
            creation_ip =>      bt_bug.new.creation_ip,    
            item_subtype =>     bt_bug.new.item_subtype,   
            content_type =>     bt_bug.new.content_type,   
            title =>            null,             
            description =>      null,             
            nls_language =>     null,             
            mime_type =>        null,             
            data =>             null              
        );

        -- create the item type row
        insert into bt_bugs
            (bug_id,
             bug_number,
             comment_content,
             comment_format,
             parent_id,
             project_id,
             creation_date,
             creation_user,
	     fix_for_version)
        values
            (v_bug_id,
             v_bug_number,
             bt_bug.new.comment_content,
             bt_bug.new.comment_format,
             v_folder_id,
             bt_bug.new.package_id,
             bt_bug.new.creation_date,
             bt_bug.new.creation_user,
	     bt_bug.new.fix_for_version);

        -- create the initial revision
        v_revision_id := bt_bug_revision.new(
            bug_revision_id =>          null,                     
            bug_id =>                   v_bug_id,                 
            component_id =>             bt_bug.new.component_id, 
            found_in_version =>         bt_bug.new.found_in_version,
            fix_for_version =>          null,                     
            fixed_in_version =>         bt_bug.new.fix_for_version,                     
            resolution =>               null,                     
            user_agent =>               bt_bug.new.user_agent,    
            summary =>                  bt_bug.new.summary,       
            creation_date =>            bt_bug.new.creation_date,
            creation_user =>            bt_bug.new.creation_user,
            creation_ip =>              bt_bug.new.creation_ip  
        );

        return v_bug_id;
    end new;

    procedure del (
        bug_id          in integer
    )
    is
        v_case_id       integer;
        foo             integer;
    begin
        -- Every bug is associated with a workflow case
        select case_id into v_case_id
        from workflow_cases
        where object_id = bt_bug.del.bug_id;

        foo := workflow_case_pkg.del(v_case_id);
        
        -- Every bug may have notifications attached to it
        -- and there is one column in the notificaitons datamodel that doesn't
        -- cascade
        for rec in (select notification_id from notifications where response_id = bt_bug.del.bug_id)
        loop
            notification.del (rec.notification_id);
        end loop;

        acs_object.del(bug_id);
        
        return;
    end del;

    function name (
        bug_id         in integer
    ) return varchar2
    is
        v_name          bt_bugs.summary%TYPE;
    begin
        select summary
        into   v_name
        from   bt_bugs
        where  bug_id = name.bug_id;

        return v_name;
    end name;

end bt_bug;
/
show errors
