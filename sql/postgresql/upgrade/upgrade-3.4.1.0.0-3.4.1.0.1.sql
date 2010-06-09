-- upgrade-3.4.1.0.0-3.4.1.0.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.1.0.0-3.4.1.0.1.sql','');



create or replace function im_project__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, integer, integer, integer, integer
) returns integer as '
DECLARE
	p_project_id	alias for $1;
	p_object_type	alias for $2;
	p_creation_date   alias for $3;
	p_creation_user   alias for $4;
	p_creation_ip	alias for $5;
	p_context_id	alias for $6;

	p_project_name	alias for $7;
	p_project_nr	alias for $8;
	p_project_path	alias for $9;
	p_parent_id	alias for $10;
	p_company_id	alias for $11;
	p_project_type_id	alias for $12;
	p_project_status_id alias for $13;

	v_project_id	integer;
BEGIN
	v_project_id := acs_object__new (
		p_project_id,
		p_object_type,
		p_creation_date,
		p_creation_user,
		p_creation_ip,
		p_context_id
	);

	insert into im_biz_objects (object_id) values (v_project_id);

	insert into im_projects (
		project_id, project_name, project_nr, 
		project_path, parent_id, company_id, project_type_id, 
		project_status_id 
	) values (
		v_project_id, p_project_name, p_project_nr, 
		p_project_path, p_parent_id, p_company_id, p_project_type_id, 
		p_project_status_id
	);
	return v_project_id;
end;' language 'plpgsql';

insert into im_biz_objects (object_id)
select	project_id
from	im_projects
where	project_id not in (
		select	object_id
		from	im_biz_objects
	)
;

