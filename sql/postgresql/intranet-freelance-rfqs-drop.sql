
-- /packages/intranet-freelance-rfqs/sql/postgresql/intranet-freelance-rfqs-drop.sql
--
-- ]project-open[ Freelance RFQ
--
-- Copyright (C) 2004 - 2009 ]project-open[
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>



select im_menu__del_module('intranet-freelance-rfqs');
select im_component_plugin__del_module('intranet-freelance-rfqs');


-- before remove priviliges remove granted permissions
create or replace function inline_revoke_permission (varchar)
returns integer as '
DECLARE
        p_priv_name     alias for $1;
BEGIN
     lock table acs_permissions_lock;

     delete from acs_permissions
     where privilege = p_priv_name;

     delete from acs_privilege_hierarchy
     where privilege = p_priv_name OR child_privilege = p_priv_name;

     PERFORM acs_privilege__drop_privilege(p_priv_name);

     return 0;

end;' language 'plpgsql';


select inline_revoke_permission('add_freelance_rfqs');
select inline_revoke_permission('view_freelance_rfqs');
select inline_revoke_permission('view_freelance_rfqs_all');



drop function im_freelance_rfq_answer__delete (integer);
drop function im_freelance_rfq_answer__name (integer);
drop function im_freelance_rfq_answer__new (
	integer, varchar, timestamptz, integer,	varchar, integer, 
	integer, integer, integer, integer
);

drop function im_freelance_rfq__delete (integer);
drop function im_freelance_rfq__name (integer);
drop function im_freelance_rfq__new (
	integer, varchar, timestamptz, integer,	varchar, integer, 
	varchar, integer, integer, integer
);


drop view im_freelance_rfq_overall_status;
drop view im_freelance_rfq_type;
drop view im_freelance_rfq_status;

drop table im_freelance_rfq_answers;
drop table im_freelance_rfqs;

delete from im_categories where category_type = 'Intranet Trans RFQ Status';
delete from im_categories where category_type = 'Intranet Trans RFQ Overall Status';



delete from acs_objects where object_type = 'im_freelance_rfq_answer';
delete from acs_objects where object_type = 'im_freelance_rfqs';

SELECT acs_object_type__drop_type ('im_freelance_rfq', 'f');
SELECT acs_object_type__drop_type ('im_freelance_rfq_answer', 'f');

