-- indicators.sql
	

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		'']po[ Live Operations Time'',
		''po_live'',
		15110,
		15000,
		''select now()::date - min(start_date)::date from im_projects;'',
		0,
		100,
		5
	);

	update im_indicators set
		indicator_section_id = 15245
	where indicator_id = v_id;

	update im_reports set
		report_description = ''Counts the days ]po[ is in operations, starting with the start_date of the first project.''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
    

    

create or replace function inline_0 ()
returns integer as '
DECLARE
	v_id			integer;
BEGIN
	v_id := im_indicator__new(
		null,
		''im_indicator'',
		now(),
		0,
		'''',
		null,
		''1'',
		''einz'',
		15110,
		15000,
		''select 1'',
		0,
		2,
		5
	);

	update im_indicators set
		indicator_section_id = NULL
	where indicator_id = v_id;

	update im_reports set
		report_description = ''''
	where report_id = v_id;

        return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



