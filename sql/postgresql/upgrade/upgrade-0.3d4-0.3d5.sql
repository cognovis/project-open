-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-01-23
-- @arch-tag: 2abf85db-45a1-4444-856d-683a01be7937
-- @cvs-id $Id$
--
select define_function_args ('rss_gen_subscr__new','subscr_id,impl_id,summary_context_id,timeout,lastbuild,object_type,creation_date;now,creation_user,creation_ip,context_id');

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
