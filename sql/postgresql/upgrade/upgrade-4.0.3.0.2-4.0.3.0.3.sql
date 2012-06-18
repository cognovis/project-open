-- upgrade-4.0.3.0.2-4.0.3.0.3.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.0.2-4.0.3.0.3.sql','');


-- Modify the project's unique constraints in order to deal
-- with duplicate projects on the top-level


-- Identify projects with duplicate project_nr
-- and make them unique by adding the project_id
--
update im_projects
set project_nr = project_nr || '.' || project_id
where project_id in (
	select	project_id
	from  	im_projects 
	where	project_nr in (
		select project_nr 
		from (
			select count(*) as cnt, project_nr 
			from im_projects 
			where parent_id is null 
			group by project_nr 
			order by cnt DESC
			) t 
		where cnt > 1
	)
);


-- Identify projects with duplicate project_path
-- and make them unique by adding the project_id
--
update im_projects
set project_path = project_path || '.' || project_id
where project_id in (
	select	project_id
	from  	im_projects 
	where	project_path in (
		select project_path 
		from (
			select count(*) as cnt, project_path 
			from im_projects 
			where parent_id is null 
			group by project_path 
			order by cnt DESC
			) t 
		where cnt > 1
	)
);


create or replace function inline_0 ()
returns integer as $body$
declare
	v_count  integer;
begin
	-- Drop the old unique constraints
	select count(*) into v_count from pg_constraint
	where lower(conname) = 'im_projects_name_un';
	IF v_count > 0 THEN alter table im_projects drop constraint im_projects_name_un; END IF;

	-- Create the new unique indices
	select count(*) into v_count from pg_class
	where lower(relname) = 'im_projects_name_un';
	IF v_count = 0 THEN 
	   	create unique index im_projects_name_un on im_projects (project_name, company_id, coalesce(parent_id,0));
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();




create or replace function inline_0 ()
returns integer as $body$
declare
	v_count  integer;
begin
	-- Drop the old unique constraints
	select count(*) into v_count from pg_constraint
	where lower(conname) = 'im_projects_nr_un';
	IF v_count > 0 THEN alter table im_projects drop constraint im_projects_nr_un; END IF;


	-- Create the new unique indices
	select count(*) into v_count from pg_class
	where lower(relname) = 'im_projects_nr_un';
	IF v_count = 0 THEN 
	   	create unique index im_projects_nr_un on im_projects (project_nr, company_id, coalesce(parent_id,0));
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();




create or replace function inline_0 ()
returns integer as $body$
declare
	v_count  integer;
begin
	-- Drop the old unique constraints
	select count(*) into v_count from pg_constraint
	where lower(conname) = 'im_projects_path_un';
	IF v_count > 0 THEN alter table im_projects drop constraint im_projects_path_un; END IF;


	-- Create the new unique indices
	select count(*) into v_count from pg_class
	where lower(relname) = 'im_projects_path_un';
	IF v_count = 0 THEN 
	   	create unique index im_projects_path_un on im_projects (project_path, company_id, coalesce(parent_id,0));
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();


