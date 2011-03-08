-- Datamodel create for faq
--
-- @author @jennie.ybos.net,@wirth.ybos.net,openacs port @samir.symphinity.com
-- 
-- @cvs-id $Id: faq-create.sql,v 1.6 2007/10/07 22:37:00 donb Exp $
--
create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''faq'',			-- object_type
	''FAQ'',			-- pretty_name
	''FAQs'',			-- pretty_plural
	''acs_object'',		-- supertype
	''FAQS'',			-- table_name
	''FAQ_ID'',		-- id_column
	null,				-- package_name
	''f'',				-- abstract_p
	null,				-- type_extension_table
	''faq__name''		-- name_method
	);

  return 0;
end;' language 'plpgsql';

select inline_0 ();
drop function inline_0 ();


create table faqs (
		faq_id    integer constraint faqs_faq_id_fk
			  references acs_objects(object_id)
			  constraint faqs_pk
			  primary key,
		faq_name  varchar (250)
		          constraint faqs_faq_name_nn   not null,
		separate_p boolean  check(separate_p in ('f','t')),
		disabled_p char(1) default 'f' check(disabled_p in ('f','t'))
);


create function inline_1 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
	''faq_q_and_a'',			-- object_type
	''FAQ_Q_and_A'',			-- pretty_name
	''FAQ_Q_and_As'',			-- pretty_plural
	''acs_object'',		-- supertype
	''FAQ_Q_AND_AS'',			-- table_name
	''ENTRY_ID'',		-- id_column
	null,				-- package_name
	''f'',				-- abstract_p
	null,				-- type_extension_table
	null		-- name_method
	);

  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


create table faq_q_and_as (
	entry_id  integer constraint faq_q_and_as_entry_id_fk
		  references acs_objects (object_id)
		  constraint faq_q_sand_a_pk
         	  primary key,
	faq_id	  integer references faqs not null,
	question  varchar (4000) not null,
	answer    varchar (4000) not null,
	-- determines the order of questions in a FAQ
	sort_key  integer not null
);



 select acs_privilege__create_privilege('faq_view_faq');
 select acs_privilege__create_privilege('faq_create_faq');
 select acs_privilege__create_privilege('faq_delete_faq');
 select acs_privilege__create_privilege('faq_modify_faq');
 select acs_privilege__create_privilege('faq_view_q_and_a');
 select acs_privilege__create_privilege('faq_create_q_and_a');
 select acs_privilege__create_privilege('faq_delete_q_and_a');
 select acs_privilege__create_privilege('faq_modify_q_and_a');
 select acs_privilege__create_privilege('faq_admin_faq');
 select acs_privilege__create_privilege('faq_admin_q_and_a');
 select acs_privilege__add_child('faq_admin_faq', 'faq_view_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_create_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_delete_faq');
 select acs_privilege__add_child('faq_admin_faq', 'faq_modify_faq');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_view_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_create_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_delete_q_and_a');
 select acs_privilege__add_child('faq_admin_q_and_a', 'faq_modify_q_and_a');
 select acs_privilege__add_child('faq_admin_faq', 'faq_admin_q_and_a');

 -- bind privileges to global names

 select acs_privilege__add_child('create','faq_create_faq');
 select acs_privilege__add_child('create','faq_create_q_and_a');
 select acs_privilege__add_child('write','faq_modify_faq');
 select acs_privilege__add_child('write','faq_modify_q_and_a');
 select acs_privilege__add_child('read','faq_view_faq');
 select acs_privilege__add_child('read','faq_view_q_and_a');
 select acs_privilege__add_child('delete','faq_delete_faq');
 select acs_privilege__add_child('delete','faq_delete_q_and_a');
 select acs_privilege__add_child('admin','faq_admin_faq');


create function inline_2 ()
returns integer as '
declare
	default_context 	acs_objects.object_id%TYPE;
	registered_users 	acs_objects.object_id%TYPE;
	the_public 				acs_objects.object_id%TYPE;
begin

  default_context = acs__magic_object_id(''default_context'');
  registered_users = acs__magic_object_id(''registered_users'');
  the_public = acs__magic_object_id(''the_public'');

  -- give the public the power to view faqs by default

  PERFORM acs_permission__grant_permission (default_context, the_public, ''faq_view_faq'');


  -- give the public the power to view q_and_as by default

  PERFORM acs_permission__grant_permission ( default_context,the_public, ''faq_view_q_and_a'');

  return 0;

end;' language 'plpgsql';


select inline_2 ();

drop function inline_2 ();


\i faq-package-create.sql
\i faq-sc-create.sql
