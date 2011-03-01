-- upgrade-3.2.3.0.0-3.2.4.0.0.sql

SELECT acs_log__debug('/packages/intranet-forum/sql/postgresql/upgrade/upgrade-3.2.3.0.0-3.2.4.0.0.sql','');


create or replace function inline_0 ()
returns integer as '
declare
        v_count                 integer;
begin
	select count(*) into v_count from im_forum_folders;
	IF v_count > 0 THEN return 0; END IF;

	insert into im_forum_folders values (0, null, null, ''Inbox'');
	insert into im_forum_folders values (1, null, null, ''Deleted'');
	insert into im_forum_folders values (2, null, null, ''Sys2'');
	insert into im_forum_folders values (3, null, null, ''Sys3'');
	insert into im_forum_folders values (4, null, null, ''Sys4'');
	insert into im_forum_folders values (5, null, null, ''Sys5'');
	insert into im_forum_folders values (6, null, null, ''Sys6'');
	insert into im_forum_folders values (7, null, null, ''Sys7'');
	insert into im_forum_folders values (8, null, null, ''Sys8'');
	insert into im_forum_folders values (9, null, null, ''Sys9'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

