--
-- Integrate mail with OpenACS
--
-- @author <a href="mailto:frank.bergmann@project-open.com">frank.bergmann@project-open.com</a>
-- @version $Id: intranet-mail-import-create.sql,v 1.3 2009/02/09 16:40:19 cvs Exp $
--

---------------------------------------------------------------------------
--
---------------------------------------------------------------------------

create sequence im_mail_import_email_stats_seq start with 1;
create table im_mail_import_email_stats (
      stat_id                 integer,
      stat_email              varchar(100),
      stat_day                timestamptz,
      stat_subject            text
);


create sequence im_mail_import_blacklist_seq start with 1;
create table im_mail_import_blacklist (
      blacklist_id            integer,
      blacklist_email         varchar(100),
      blacklist_day           timestamptz
);





---------------------------------------------------------------------------
--
---------------------------------------------------------------------------

create or replace function inline_0 ()
returns integer as '
declare
        v_menu                  integer;
        v_admin_menu             integer;
        v_admins                integer;
BEGIN
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select menu_id into v_admin_menu from im_menus where label=''admin'';

    v_menu := im_menu__new (
        null,			-- p_menu_id
        ''acs_object'',		-- object_type
        now(),			-- creation_date
        null,			-- creation_user
        null,			-- creation_ip
        null,			-- context_id
        ''intranet-mail-import'',  -- package_name
        ''mail_import'',	-- label
        ''Mail Import'',	-- name
        ''/intranet-mail-import/'',-- url
        350,			-- sort_order
        v_admin_menu,		-- parent_menu_id
        null			-- p_visible_tcl
    );

    PERFORM acs_permission__grant_permission(v_menu, v_admins, ''read'');

    return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



---------------------------------------------------------------------------
--
---------------------------------------------------------------------------



-- create dummy relationship -
-- we don't want to create the specified table
select acs_rel_type__create_type (
   'im_mail_from',	-- relationship (object) name
   'Mail From',		-- pretty name
   'Mail From',		-- pretty plural
   'relationship',	-- supertype
   'im_mail_import_from', -- table_name
   'rel_id',		-- id_column
   'im_mail_import_from', -- package_name
   'acs_object',	-- object_type_one
   'member',		-- role_one
    0,			-- min_n_rels_one
    null,		-- max_n_rels_one
   'person',		-- object_type_two
   'member',		-- role_two
   0,			-- min_n_rels_two
   null			-- max_n_rels_two
);


-- create dummy relationship -
-- we don't want to create the specified table
select acs_rel_type__create_type (
   'im_mail_to',	-- relationship (object) name
   'Mail To',		-- pretty name
   'Mail To',		-- pretty plural
   'relationship',	-- supertype
   'im_mail_import_to',	-- table_name
   'rel_id',		-- id_column
   'im_mail_import_to',	-- package_name
   'acs_object',	-- object_type_one
   'member',		-- role_one
    0,			-- min_n_rels_one
    null,		-- max_n_rels_one
   'person',		-- object_type_two
   'member',		-- role_two
   0,			-- min_n_rels_two
   null			-- max_n_rels_two
);



-- create dummy relationship -
-- we don't want to create the specified table
select acs_rel_type__create_type (
   'im_mail_related_to',        -- relationship (object) name
   'Mail Related To',           -- pretty name
   'Mail Related To',           -- pretty plural
   'relationship',              -- supertype
   'im_mail_import_related_to', -- table_name
   'rel_id',                    -- id_column
   'im_mail_import_related_to', -- package_name
   'acs_object',                -- object_type_one
   'member',                    -- role_one
    0,                          -- min_n_rels_one
    null,                       -- max_n_rels_one
   'acs_object',                -- object_type_two
   'member',                    -- role_two
   0,                           -- min_n_rels_two
   null                         -- max_n_rels_two
);




-------------------------------------------
-- create components

-- Delete components and menus
-- select  im_component_plugin__del_module('intranet-mail-import');
-- select  im_menu__del_module('intranet-mail-import');


SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'User Mail Component',		-- plugin_name
        'intranet-mail-import',         -- package_name
        'left',                         -- location
        '/intranet/users/view',         -- page_url
        null,                           -- view_name
        90,                             -- sort_order
        'im_mail_import_user_component -rel_user_id $user_id' -- component_tcl
    );


SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Project Mail Component',          -- plugin_name
        'intranet-mail-import',         -- package_name
        'left',                         -- location
        '/intranet/projects/view',         -- page_url
        null,                           -- view_name
        120,                             -- sort_order
        'im_mail_import_project_component -project_id $project_id' -- component_tcl
    );




--	 select im_mail_import_new_message (
--		:spam_id,	 -- spam_id
--		null,	   -- reply_to
--		null,	   -- sent_date
--		null,	   -- sender
--		null,	   -- rfc822_id
--		:subject,	 -- title
--		:html,	  -- html_text
--		:plain,	 -- plain_text
--		:context_id,	-- context_id
--		now(),	  -- creation_date
--		:user_id,	 -- creation_user
--		:peeraddr,	-- creation_ip
--		'spam_message', -- object_type
--		:approved_p,	-- approved_p
--		to_timestamp(:send_date, 'yyyy-mm-dd hh:mi:ss') -- send_date
--	 );


create or replace function im_mail_import_new_message (integer,varchar,timestamptz,text,varchar,text,varchar,varchar,integer,timestamptz,integer,varchar,varchar,boolean,timestamptz,varchar,varchar)
returns integer as '
declare
	p_cr_item_id	alias for $1; 	-- default null
	reply_to	alias for $2; 	-- default null
	sent_date	alias for $3; 	-- default sysdate
	sender		alias for $4; 	-- default null
	rfc822_id	alias for $5; 	-- default null
	title		alias for $6; 	-- default null
	html_text	alias for $7; 	-- default null
	plain_text	alias for $8; 	-- default null
	context_id	alias for $9;
	creation_date   alias for $10;	-- default sysdate
	creation_user   alias for $11;	-- default null
	creation_ip     alias for $12;	-- default null
	object_type     alias for $13;	-- default acs_mail_body
	p_approved_p    alias for $14;	-- default f
	p_send_date     alias for $15;
	header_from	alias for $16;
	header_to	alias for $17;

	v_link_id	 acs_objects.object_id%TYPE;
	v_body_id	acs_objects.object_id%TYPE;
	v_content_obj   acs_mail_bodies.content_item_id%TYPE;
	v_html_id 	acs_mail_bodies.content_item_id%TYPE;
	v_text_id	 acs_mail_bodies.content_item_id%TYPE;
begin
	select acs_mail_body__new (
		null,			-- p_body_id
		null,			-- p_body_reply_to
		null,			-- p_body_from
		sent_date,		-- p_body_date
		rfc822_id,		-- p_header_message_id
		reply_to,		-- p_header_reply_to
		title,			-- p_header_subject
		header_from,		-- p_header_from
		header_to,		-- p_header_to
		null,			-- p_content_item_id
		''acs_mail_body'', 	-- p_object_type
		to_date(to_char(creation_date, ''YYYY-MM-DD''), ''YYYY-MM-DD''),  -- p_creation_date
		creation_user,  	-- p_creation_user
		creation_ip,    	-- p_creation_ip
		context_id		-- p_context_id
	) into v_body_id;

	if plain_text is not null then
		 select spam__new_content(
			context_id, 	-- context_id
			creation_date,  -- creation_date
			creation_user,  -- creation_user
			creation_ip,	-- creation_ip
			null,	   	-- object_type
			''text/plain'', -- mime_type
			plain_text, 	-- text
			v_body_id	-- body_id
		) into v_text_id;
	end if;

	if html_text is not null then
		select spam__new_content(
			context_id, 	-- context_id
			creation_date,  -- creation_date
			creation_user,  -- creation_user
			creation_ip,	-- creation_ip
			null,		-- object_type
			''text/html'',  -- mime_type
			html_text,	-- text
			v_body_id	-- body_id
		) into v_html_id;
	end if;


	-- now we have the message header set up.  now see what type
	-- of content we create.  We create a straight text/* content
	-- object if we only have either html_text or plain_text set,
	-- but we create a multipart/alternative if we have both.

	if html_text IS NOT NULL and plain_text IS NOT NULL then 
		-- we have both html and plain
		select acs_mail_multipart__new(
			null,			-- p_multipart_id
			''alternative'',	-- p_multipart_kind
			''acs_mail_multipart'', -- p_object_type
			creation_date,		-- p_creation_date
			creation_user,		-- p_creation_user
			creation_ip,		-- p_creation_ip
			context_id		-- p_context_id

		) into v_content_obj;
		perform acs_mail_multipart__add_content(v_content_obj, v_text_id);
		perform acs_mail_multipart__add_content(v_content_obj, v_html_id);
	else if plain_text is not null then
		v_content_obj := v_text_id;
	     else if html_text is not null then
		v_content_obj := v_html_id;
		  end if;
	     end if;
	end if;

	perform	acs_mail_body__set_content_object(v_body_id, v_content_obj);

	return v_body_id;
end;
' language 'plpgsql';

