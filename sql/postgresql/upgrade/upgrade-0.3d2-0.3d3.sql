--
-- Adding defaulting for v_summary_context_id, to support
-- the file-storage implementation of RssGenerationSubscriber.
--

drop function rss_gen_subscr__new (
    integer,                   -- subscr_id
    integer,                   -- impl_id
    varchar,                   -- summary_context_id
    integer,                   -- timeout
    timestamptz,               -- lastbuild
    varchar,                   -- object_type
    timestamptz,               -- creation_date
    integer,                   -- creation_user
    varchar,                   -- creation_ip
    integer                    -- context_id
);

create function rss_gen_subscr__new (
    integer,                   -- subscr_id
    integer,                   -- impl_id
    varchar,                   -- summary_context_id
    integer,                   -- timeout
    timestamptz,               -- lastbuild
    varchar,                   -- object_type
    timestamptz,               -- creation_date
    integer,                   -- creation_user
    varchar,                   -- creation_ip
    integer                    -- context_id
) returns integer as '
declare
  p_subscr_id			alias for $1;
  p_impl_id			alias for $2;
  p_summary_context_id		alias for $3;
  p_timeout			alias for $4;
  p_lastbuild			alias for $5;
  p_object_type			alias for $6;           -- default ''rss_gen_subscr''
  p_creation_date		alias for $7;		-- default now()
  p_creation_user		alias for $8;		-- default null
  p_creation_ip			alias for $9;		-- default null
  p_context_id			alias for $10;		-- default null
  v_subscr_id			rss_gen_subscrs.subscr_id%TYPE;
  v_summary_context_id  rss_gen_subscrs.summary_context_id%TYPE;
begin
	v_subscr_id := acs_object__new (
		p_subscr_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

        if p_summary_context_id is null then
          v_summary_context_id := v_subscr_id;
        else
          v_summary_context_id := p_summary_context_id;
        end if;

	insert into rss_gen_subscrs
	  (subscr_id, impl_id, summary_context_id, timeout, lastbuild)
	values
	  (v_subscr_id, p_impl_id, v_summary_context_id, p_timeout, p_lastbuild);

	return v_subscr_id;

end;' language 'plpgsql';
