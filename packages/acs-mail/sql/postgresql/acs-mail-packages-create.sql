--
-- packages/acs-mail/sql/acs-mail-create-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id: acs-mail-packages-create.sql,v 1.4 2009/01/31 13:53:56 cvs Exp $
--

-- Package Implementations ---------------------------------------------

create function acs_mail_gc_object__new (integer,varchar,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_gc_object_id  alias for $1;    -- default null
    p_object_type   alias for $2;    -- default acs_mail_gc_object
    p_creation_date alias for $3;    -- default now
    p_creation_user alias for $4;    -- default null
    p_creation_ip   alias for $5;    -- default null
    p_context_id    alias for $6;    -- default null
    v_object_id   integer;
begin
    v_object_id := acs_object__new (
		p_gc_object_id,		-- object_id 
		p_object_type,		-- object_type 
		p_creation_date,	-- creation_date 
		p_creation_user,	-- creation_user 
		p_creation_ip,		-- creation_ip 
		p_context_id		-- context_id 
    );

    insert into acs_mail_gc_objects values ( v_object_id );

    return v_object_id;
end;
' language 'plpgsql';

create function acs_mail_gc_object__delete(integer) 
returns integer as '
declare
	p_gc_object_id	alias for $1;
begin
    delete from acs_mail_gc_objects
		where gc_object_id = p_gc_object_id;

	perform acs_object__delete( p_gc_object_id );

    return 1;
end;
' language 'plpgsql';

-- first create a CR item.
-- then call acs_mail_body__new with the CR item's item_id

create function acs_mail_body__new (
	integer,integer,integer,
	timestamptz,varchar,varchar,
	text,text,text,
	integer,varchar,date,
	integer,varchar,integer
) returns integer as ' 
declare
	p_body_id			alias for $1;    -- default null
	p_body_reply_to		alias for $2;    -- default null
	p_body_from			alias for $3;    -- default null
	p_body_date			alias for $4;    -- default null
	p_header_message_id	alias for $5;    -- default null
	p_header_reply_to   alias for $6;    -- default null
	p_header_subject    alias for $7;    -- default null
	p_header_from       alias for $8;    -- default null
	p_header_to         alias for $9;    -- default null
	p_content_item_id   alias for $10;   -- default null
	p_object_type       alias for $11;   -- default acs_mail_body
	p_creation_date     alias for $12;   -- default now()
	p_creation_user     alias for $13;   -- default null
	p_creation_ip       alias for $14;   -- default null
	p_context_id        alias for $15;   -- default null
    v_object_id         integer;
	v_system_url		varchar;
	v_domain_name		varchar;
	v_idx				integer;
	v_header_message_id	acs_mail_bodies.header_message_id%TYPE;
begin

     v_object_id := acs_mail_gc_object__new (
		p_body_id,			-- gc_object_id 
		p_object_type,		-- object_type 
		p_creation_date,	-- creation_date 
		p_creation_user,	-- creation_user 
		p_creation_ip,		-- creation_ip 
		p_context_id		-- context_id 
     );

	-- vinodk: get SystemURL parameter and use it to extract domain name
	select apm__get_value(package_id, ''SystemURL'') into v_system_url
		from apm_packages where package_key=''acs-kernel'';
	v_idx := position(''http://'' in v_system_url);
	v_domain_name := trim (substr(v_system_url, v_idx + 7));

	v_header_message_id := coalesce (p_header_message_id,
		current_date || ''.'' || v_object_id || ''@'' || 
		v_domain_name || ''.sddd'');

    insert into acs_mail_bodies
        (body_id, body_reply_to, body_from, body_date, 
          header_message_id, header_reply_to, header_subject, header_from,
		 header_to, content_item_id)
    values
         (v_object_id, p_body_reply_to, p_body_from, p_body_date,
          v_header_message_id, p_header_reply_to, p_header_subject, p_header_from,
          p_header_to, p_content_item_id);

     return v_object_id;
end;
' language 'plpgsql';


create function acs_mail_body__delete(integer)
returns integer as ' 
declare
	p_body_id		alias for $1;
begin
	perform acs_mail_gc_object__delete( p_body_id );

    return 1;
end;
' language 'plpgsql';

create or replace function acs_mail_body__body_p(integer) 
returns boolean as '
declare
	p_object_id		alias for $1;
	v_check_body_id		integer;
begin
	select count(body_id) into v_check_body_id
	from acs_mail_bodies where body_id = p_object_id;

	if v_check_body_id <> 0 then
		return ''t'';
	else
		return ''f'';
	end if;
end;
' language 'plpgsql' stable;

create function acs_mail_body__clone (integer,integer,varchar,timestamptz,integer,varchar,integer) 
returns integer as '
declare 
	p_old_body_id       alias for $1;
	p_body_id           alias for $2;    -- default null
	p_object_type       alias for $3;    -- default acs_mail_body
	p_creation_date     alias for $4;    -- default now()
	p_creation_user     alias for $5;    -- default null
	p_creation_ip       alias for $6;    -- default null
	p_context_id        alias for $7;    -- default null
    v_object_id         integer;
    v_body_reply_to		integer;
    v_body_from         integer;
    v_body_date         timestamptz;
    v_header_message_id varchar;
    v_header_reply_to   varchar;
    v_header_subject    text;
    v_header_from       text;
    v_header_to         text;
    v_content_item_id integer;
begin
     select body_reply_to, body_from, body_date,
            header_reply_to, header_subject, header_from, header_to,
            content_item_id
         into v_body_reply_to, v_body_from, v_body_date,
            v_header_reply_to, v_header_subject, v_header_from, v_header_to,
            v_content_item_id
         from acs_mail_bodies
         where body_id = p_old_body_id;

     v_object_id := acs_mail_body__new (
		p_body_id,				-- body_id 
		v_body_reply_to,		-- body_reply_to 
		v_body_from,			-- body_from 
		v_body_date,			-- body_date 
		v_header_reply_to,		-- header_reply_to 
		v_header_subject,		-- header_subject 
		v_header_from,			-- header_from 
		v_header_to,			-- header_to 
		v_content_item_id,		-- content_item_id 
		p_object_type,			-- object_type 
		p_creation_date,		-- creation_date 
		p_creation_user,		-- creation_user 
		p_creation_ip,			-- creation_ip 
		p_context_id			-- context_id 
     );

     return v_object_id;
end;
' language 'plpgsql';

create function acs_mail_body__set_content_object (integer,integer) 
returns integer as '
declare
	p_body_id				alias for $1;
	p_content_item_id		alias for $2;
begin
    update acs_mail_bodies
        set content_item_id = p_content_item_id
        where body_id = p_body_id;

    return 1;
end;
' language 'plpgsql';

----
--create or replace package body acs_mail_multipart
create function acs_mail_multipart__new (integer,varchar,varchar,
timestamptz,integer,varchar,integer) 
returns integer as '
declare
	p_multipart_id		alias for $1;    -- default null,
	p_multipart_kind	alias for $2;
    p_object_type		alias for $3;    -- default acs_mail_multipart
    p_creation_date		alias for $4;    -- default now()
    p_creation_user		alias for $5;    -- default null
    p_creation_ip		alias for $6;    -- default null
    p_context_id		alias for $7;    -- default null
    v_object_id			integer;
begin
    v_object_id := acs_mail_gc_object__new (
		p_multipart_id,		-- gc_object_id 
		p_object_type,		-- object_type 
		p_creation_date,	-- creation_date 
		p_creation_user,	-- creation_user 
		p_creation_ip,		-- creation_ip 
		p_context_id		-- context_id 
    );
	
	insert into acs_mail_multiparts 
	 (multipart_id, multipart_kind)
	values 
	 (v_object_id, p_multipart_kind);

    return v_object_id;
end;
' language 'plpgsql';

create function acs_mail_multipart__delete (integer)
returns integer as '
declare
	p_multipart_id		alias for $1;
begin
	perform acs_mail_gc_object__delete( p_multipart_id );

    return 1;
end;
' language 'plpgsql';

create or replace function acs_mail_multipart__multipart_p (integer)
returns boolean as '
declare
	p_object_id				alias for $1;
    v_check_multipart_id    integer;
begin
	select count(multipart_id) into v_check_multipart_id
      from acs_mail_multiparts
	  where multipart_id = p_object_id;

    if v_check_multipart_id <> 0 then
        return ''t'';
    else
        return ''f'';
    end if;
end;
' language 'plpgsql' stable;

 -- Add content at a specific index.  If the sequence number is null,
 -- below one, or higher than the highest item already available,
 -- adds at the end.  Otherwise, inserts and renumbers others.

create function acs_mail_multipart__add_content (integer,integer)
returns integer as ' 
declare
	p_multipart_id			alias for $1;
    p_content_item_id		alias for $2;
    v_multipart_id			integer;
    v_max_num				integer;
begin
    -- get a row lock on the multipart item
    select multipart_id into v_multipart_id from acs_mail_multiparts
        where multipart_id = p_multipart_id for update;

    select coalesce(max(sequence_number),0) into v_max_num
        from acs_mail_multipart_parts
        where multipart_id = p_multipart_id;

    insert into acs_mail_multipart_parts
        (multipart_id, sequence_number, content_item_id)
    values
        (p_multipart_id, v_max_num + 1, p_content_item_id);

	return v_max_num + 1;
end;
' language 'plpgsql';

--end acs_mail_multipart;

--create or replace package body acs_mail_link__
create function acs_mail_link__new (integer,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
	p_mail_link_id			alias for $1;    -- default null
	p_body_id				alias for $2;
	p_context_id			alias for $3;    -- default null
	p_creation_date			alias for $4;    -- default now()
	p_creation_user			alias for $5;    -- default null
	p_creation_ip			alias for $6;    -- default null
	p_object_type			alias for $7;    -- default acs_mail_link
    v_mail_link_id			acs_mail_links.mail_link_id%TYPE;
begin
    v_mail_link_id := acs_object__new (
		p_mail_link_id,		-- object_id 
		p_object_type,		-- object_type 
		p_creation_date,	-- creation_date 
		p_creation_user,	-- creation_user 
		p_creation_ip,		-- creation_ip 
		p_context_id		-- context_id 
    );

    insert into acs_mail_links 
	 ( mail_link_id, body_id )
	values 
	 ( v_mail_link_id, p_body_id );

    return v_mail_link_id;
end;
' language 'plpgsql';

create function acs_mail_link__delete (integer)
returns integer as '
declare
	p_mail_link_id			alias for $1;
begin
	perform acs_object__delete( p_mail_link_id );

    return 1;
end;
' language 'plpgsql';

create or replace function acs_mail_link__link_p (integer)
returns boolean as '
declare
	p_object_id				alias for $1;
    v_check_link_id			integer;
begin
    select count(mail_link_id) into v_check_link_id
      from acs_mail_links
      where mail_link_id = p_object_id;

    if v_check_link_id <> 0 then
        return ''t'';
    else
        return ''f'';
    end if;
end;
' language 'plpgsql' stable;

--end acs_mail_link;

