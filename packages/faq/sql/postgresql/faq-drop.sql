-- @author jennie@ybos.net
-- @author wirth@ybos.net
--openacs port @samir.symphinity.com

--drop functions
drop function faq__new_q_and_a (integer,integer,varchar,varchar,integer,varchar,timestamptz,integer,varchar,integer);
drop function faq__delete_q_and_a (integer);
drop function faq__new_faq (integer, varchar, boolean,varchar,timestamptz,integer,varchar,integer );
drop function faq__delete_faq (integer);
drop function faq__name (integer);
drop function faq__clone (integer,integer);

--drop permissions
delete from acs_permissions where object_id in (select entry_id from faq_q_and_as);
delete from acs_permissions where object_id in (select faq_id from faqs);


create function inline_0()
returns integer as '
declare
	object_rec		record;
  default_context 	acs_objects.object_id%TYPE;
  registered_users 	acs_objects.object_id%TYPE;
  the_public 				acs_objects.object_id%TYPE;
begin


	--drop objects

	for object_rec in select object_id from acs_objects where object_type=''faq''
	loop
		PERFORM acs_object__delete( object_rec.object_id );
	end loop;

	for object_rec in select object_id from acs_objects where object_type=''faq_q_and_a''
	loop
		PERFORM acs_object__delete( object_rec.object_id );
	end loop;



-- bind privileges to global names

  default_context := acs__magic_object_id(''default_context'');
  registered_users := acs__magic_object_id(''registered_users'');
  the_public := acs__magic_object_id(''the_public'');

  -- revoke from the public the power to view faqs

  PERFORM acs_permission__revoke_permission (default_context, the_public, ''faq_view_faq'');


  -- revoke from the public the power to view q_and_as

  PERFORM acs_permission__revoke_permission ( default_context,the_public, ''faq_view_q_and_a'');



--drop permissions
	PERFORM acs_privilege__remove_child(''create'',''faq_create_faq'');
	PERFORM acs_privilege__remove_child(''create'',''faq_create_q_and_a'');
	PERFORM acs_privilege__remove_child(''write'',''faq_modify_faq'');
	PERFORM acs_privilege__remove_child(''write'',''faq_modify_q_and_a'');
	PERFORM acs_privilege__remove_child(''read'',''faq_view_faq'');
	PERFORM acs_privilege__remove_child(''read'',''faq_view_q_and_a'');
	PERFORM acs_privilege__remove_child(''delete'',''faq_delete_faq'');
	PERFORM acs_privilege__remove_child(''delete'',''faq_delete_q_and_a'');
	PERFORM acs_privilege__remove_child(''admin'',''faq_admin_faq'');

	PERFORM acs_privilege__remove_child(''faq_admin_faq'', ''faq_view_faq'');
	PERFORM acs_privilege__remove_child(''faq_admin_faq'', ''faq_create_faq'');
	PERFORM acs_privilege__remove_child(''faq_admin_faq'', ''faq_delete_faq'');
	PERFORM acs_privilege__remove_child(''faq_admin_faq'', ''faq_modify_faq'');
	PERFORM acs_privilege__remove_child(''faq_admin_q_and_a'', ''faq_view_q_and_a'');
	PERFORM acs_privilege__remove_child(''faq_admin_q_and_a'', ''faq_create_q_and_a'');
	PERFORM acs_privilege__remove_child(''faq_admin_q_and_a'', ''faq_delete_q_and_a'');
	PERFORM acs_privilege__remove_child(''faq_admin_q_and_a'', ''faq_modify_q_and_a'');
	PERFORM acs_privilege__remove_child(''faq_admin_faq'', ''faq_admin_q_and_a'');

  	PERFORM acs_privilege__drop_privilege(''faq_view_faq'');
	PERFORM acs_privilege__drop_privilege(''faq_create_faq'');
	PERFORM acs_privilege__drop_privilege(''faq_delete_faq'');
	PERFORM acs_privilege__drop_privilege(''faq_modify_faq'');
	PERFORM acs_privilege__drop_privilege(''faq_view_q_and_a'');
	PERFORM acs_privilege__drop_privilege(''faq_create_q_and_a'');
	PERFORM acs_privilege__drop_privilege(''faq_delete_q_and_a'');
	PERFORM acs_privilege__drop_privilege(''faq_modify_q_and_a'');
	PERFORM acs_privilege__drop_privilege(''faq_admin_faq'');
	PERFORM acs_privilege__drop_privilege(''faq_admin_q_and_a'');
  			
	return 0;
end;' language 'plpgsql';

select inline_0();

drop function inline_0();



--drop table
drop table faq_q_and_as;
drop table faqs;


--drop type
select acs_object_type__drop_type(
	   'faq',
	   't'
	);
select acs_object_type__drop_type(
	   'faq_q_and_a',
	   't'
	);

















