create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''rss_gen_subscr'',		 	-- object_type
	''RSS Generation Subscription'',	-- pretty_name
	''RSS Generation Subscriptions'',	-- pretty_plural
	''acs_object'',				-- supertype
	''rss_gen_subscrs'',			-- table_name
	''subscr_id'',				-- id_column
	null,					-- package_name
	''f'',					-- abstract_p
	null,					-- type_extension_table
	''rss_gen_subscr__name''		-- name_method
	);

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

create function inline_1 ()
returns integer as '
begin
    PERFORM acs_attribute__create_attribute (
	  ''rss_gen_subscr'',			-- object_type
	  ''IMPL_ID'',				-- attribute_name
	  ''integer'',				-- datatype
	  ''Implementation ID'',		-- pretty_name
	  ''Implementation IDs'',		-- pretty_plural
	  null,					-- table_name
	  null,					-- column_name
	  null,					-- default_value
	  1,					-- min_n_values
	  1,					-- max_n_values
	  null,					-- sort_order
	  ''type_specific'',			-- storage
	  ''f''					-- static_p
	);

    PERFORM acs_attribute__create_attribute (
	  ''rss_gen_subscr'',			-- object_type
	  ''SUMMARY_CONTEXT_ID'',		-- attribute_name
	  ''integer'',				-- datatype
	  ''Context Identifier'',		-- pretty_name
	  ''Context Identifiers'',		-- pretty_plural
	  null,					-- table_name
	  null,					-- column_name
	  null,					-- default_value
	  1,					-- min_n_values
	  1,					-- max_n_values
	  null,					-- sort_order
	  ''type_specific'',			-- storage
	  ''f''					-- static_p
	);

    PERFORM acs_attribute__create_attribute (
	  ''rss_gen_subscr'',			-- object_type
	  ''TIMEOUT'',				-- attribute_name
	  ''integer'',				-- datatype
	  ''Timeout'',				-- pretty_name
	  ''Timeouts'',				-- pretty_plural
	  null,					-- table_name
	  null,					-- column_name
	  null,					-- default_value
	  1,					-- min_n_values
	  1,					-- max_n_values
	  null,					-- sort_order
	  ''type_specific'',			-- storage
	  ''f''					-- static_p
	);

    PERFORM acs_attribute__create_attribute (
	  ''rss_gen_subscr'',			-- object_type
	  ''LASTBUILD'',				-- attribute_name
	  ''integer'',				-- datatype
	  ''Last Build'',			-- pretty_name
	  ''Last Builds'',			-- pretty_plural
	  null,					-- table_name
	  null,					-- column_name
	  null,					-- default_value
	  1,					-- min_n_values
	  1,					-- max_n_values
	  null,					-- sort_order
	  ''type_specific'',			-- storage
	  ''f''					-- static_p
	);

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();

create table rss_gen_subscrs (
   subscr_id                      integer
				  constraint rss_gen_subscrs_id_fk
				  references acs_objects(object_id)
				  constraint rss_gen_subscrs_id_pk
				  primary key,
   impl_id			  integer
				  constraint rss_gen_subscrs_impl_nn
				  not null
				  constraint rss_gen_subscrs_impl_fk
				  references acs_sc_impls(impl_id),
   summary_context_id		  integer
				  constraint rss_gen_subscrs_ctx_nn
				  not null
				  constraint rss_gen_subscrs_ctx_fk
                                  references acs_objects(object_id),
   timeout			  integer
				  constraint rss_gen_subscrs_timeout_nn
				  not null,
   lastbuild			  timestamptz,
   last_ttb                       integer,
   channel_title                  varchar(200),
   channel_link                   varchar(1000),
   constraint rss_gen_subscrs_impl_con_un
   unique (impl_id,summary_context_id)
);

comment on table rss_gen_subscrs is '
   Table for storing the different parts of the site we will generate
   summaries for.
';

comment on column rss_gen_subscrs.subscr_id is '
   Subscriptions are ACS objects.  They will typically inherit
   permission from a package instance.
';

comment on column rss_gen_subscrs.impl_id is '
   The implementation which will provide summary information and
   update status.
';

comment on column rss_gen_subscrs.summary_context_id is '
   An identifier unique to the site section whose content is to be
   summarized.  A context identifier need not be a package instance
   id.  We will suggest a convention but the format is entirely up to
   the implementors.
';

comment on column rss_gen_subscrs.timeout is '
   The minimum number of seconds between summary builds. 
';

comment on column rss_gen_subscrs.lastbuild is '
   Accounting column for use by rss generation service.
';

comment on column rss_gen_subscrs.last_ttb is '
   Another accounting column.  The last time to build (in seconds).
';

comment on column rss_gen_subscrs.channel_title is '
   Used for display purposes.
';

comment on column rss_gen_subscrs.channel_link is '
   Used for display purposes.
';

select define_function_args ('rss_gen_subscr__new','p_subscr_id,p_impl_id,p_summary_context_id,p_timeout,p_lastbuild;now,p_object_type,p_creation_date;now,p_creation_user,p_creation_ip,p_context_id');
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

create function rss_gen_subscr__name (integer)
returns varchar as '
declare
  p_subscr_id				alias for $1;
begin
	return ''RSS Generation Subscription #'' || p_subscr_id;
end;' language 'plpgsql';

select define_function_args('rss_gen_subscr__del','subscr_id');
create or replace function rss_gen_subscr__del (integer)
returns integer as '
declare
  p_subscr_id     alias for $1;
begin
	delete from acs_permissions
		   where object_id = p_subscr_id;

	delete from rss_gen_subscrs
		   where subscr_id = p_subscr_id;

	raise NOTICE ''Deleting subscription...'';
	PERFORM acs_object__delete(p_subscr_id);

	return 0;

end;' language 'plpgsql';

create or replace function rss_gen_subscr__delete (integer)
returns integer as '
declare
  p_subscr_id     alias for $1;
begin
  return rss_gen_subscr__del (p_subscr_id);
end;' language 'plpgsql';
