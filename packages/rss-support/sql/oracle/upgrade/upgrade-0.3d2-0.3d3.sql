--
-- Adding defaulting for v_summary_context_id, to support
-- the file-storage implementation of RssGenerationSubscriber.
--

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
