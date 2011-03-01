--
-- Object Types
--
declare
begin
    acs_object_type.create_type (
    'rss_gen_subscr',		-- object_type
    'RSS Generation Subscription',	-- pretty_name
    'RSS Generation Subscriptions',	-- pretty_plural
    'acs_object',			-- supertype
    'rss_gen_subscrs',		-- table_name
    'subscr_id',			-- id_column
    null,				-- package_name
    'f',				-- abstract_p
    null,				-- type_extension_table
    'rss_gen_subscr.name'		-- name_method
    );
end; 
/ 
show errors;

declare 
 attr_id acs_attributes.attribute_id%TYPE; 
begin
  attr_id := acs_attribute.create_attribute ( 
    object_type    => 'rss_gen_subscr', 
    attribute_name => 'IMPL_ID', 
    pretty_name    => 'Implementation ID', 
    pretty_plural  => 'Implementation IDs', 
    datatype       => 'integer' ,
    storage	   => 'type_specific',
    static_p	   => 'f',
    min_n_values   => 1,
    max_n_values   => 1
  );
end; 
/ 
show errors;

declare 
 attr_id acs_attributes.attribute_id%TYPE; 
begin
  attr_id := acs_attribute.create_attribute ( 
    object_type    => 'rss_gen_subscr', 
    attribute_name => 'SUMMARY_CONTEXT_ID', 
    pretty_name    => 'Context Identifier', 
    pretty_plural  => 'Context Identifiers', 
    datatype       => 'integer' ,
    storage	   => 'type_specific',
    static_p	   => 'f',
    min_n_values   => 1,
    max_n_values   => 1
  );
end; 
/ 
show errors;

declare 
 attr_id acs_attributes.attribute_id%TYPE; 
begin
  attr_id := acs_attribute.create_attribute ( 
    object_type    => 'rss_gen_subscr', 
    attribute_name => 'TIMEOUT', 
    pretty_name    => 'Timeout', 
    pretty_plural  => 'Timeouts', 
    datatype       => 'integer' ,
    storage	   => 'type_specific',
    static_p	   => 'f',
    min_n_values   => 1,
    max_n_values   => 1
  );
end; 
/ 
show errors;

declare 
 attr_id acs_attributes.attribute_id%TYPE; 
begin
  attr_id := acs_attribute.create_attribute ( 
    object_type    => 'rss_gen_subscr', 
    attribute_name => 'LASTBUILD', 
    pretty_name    => 'Last Build', 
    pretty_plural  => 'Last Builds', 
    datatype       => 'integer' ,
    storage	   => 'type_specific',
    static_p	   => 'f',
    min_n_values   => 1,
    max_n_values   => 1
  );
end; 
/ 
show errors;

create table rss_gen_subscrs (
    subscr_id number not null, 
    impl_id number not null, 
    summary_context_id number not null, 
    timeout number not null, 
    lastbuild date, 
    last_ttb number, 
    channel_title varchar2(200), 
    channel_link varchar2(1000), 
    constraint rss_gen_subscrs_id_pk primary key(subscr_id), 
    constraint rss_gen_subscrs_id_fk foreign key(subscr_id) 
    references acs_objects(object_id), 
    constraint rss_gen_subscrs_impl_fk foreign key(impl_id) 
    references acs_sc_impls(impl_id), 
    constraint rss_gen_subscrs_ctx_fk foreign key(summary_context_id) 
    references acs_objects(object_id),
    constraint rss_gen_subscrs_impl_con_un unique(impl_id,summary_context_id)
);

create or replace package rss_gen_subscr
as
    function new (
        p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE,
        p_impl_id		in rss_gen_subscrs.impl_id%TYPE,
        p_summary_context_id	in rss_gen_subscrs.summary_context_id%TYPE,
        p_timeout		in rss_gen_subscrs.timeout%TYPE,
	p_lastbuild		in rss_gen_subscrs.lastbuild%TYPE,
        p_object_type		in acs_objects.object_type%TYPE default 'rss_gen_subscr',
        p_creation_date		in acs_objects.creation_date%TYPE default sysdate,
        p_creation_user		in acs_objects.creation_user%TYPE default null,
        p_creation_ip		in acs_objects.creation_ip%TYPE default null,
        p_context_id		in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE;

    function name (
	p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE
    ) return varchar2;

    function del (
	p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE
    ) return number;

end rss_gen_subscr;
/
show errors

create or replace package body rss_gen_subscr
as
    function new (
        p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE,
        p_impl_id		in rss_gen_subscrs.impl_id%TYPE,
        p_summary_context_id	in rss_gen_subscrs.summary_context_id%TYPE,
        p_timeout		in rss_gen_subscrs.timeout%TYPE,
	p_lastbuild		in rss_gen_subscrs.lastbuild%TYPE,
        p_object_type		in acs_objects.object_type%TYPE default 'rss_gen_subscr',
        p_creation_date		in acs_objects.creation_date%TYPE default sysdate,
        p_creation_user		in acs_objects.creation_user%TYPE default null,
        p_creation_ip		in acs_objects.creation_ip%TYPE default null,
        p_context_id		in acs_objects.context_id%TYPE default null
    ) return acs_objects.object_id%TYPE
    is
      v_subscr_id		rss_gen_subscrs.subscr_id%TYPE;
      v_summary_context_id    rss_gen_subscrs.summary_context_id%TYPE;
    begin
	v_subscr_id := acs_object.new (
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
    end new;

    function name (
	p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE
    ) return varchar2
    is
    begin
	return 'RSS Generation Subscription #'||p_subscr_id;
    end name;

    function del (
	p_subscr_id		in rss_gen_subscrs.subscr_id%TYPE
    ) return number
    is
    begin
	delete from acs_permissions where object_id = p_subscr_id;

	delete from rss_gen_subscrs where subscr_id = p_subscr_id;

	acs_object.del(p_subscr_id);

	return 0;
    end del;

end rss_gen_subscr;
/
show errors
