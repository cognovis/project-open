-- /packages/intranet-invoices/sql/postgresql/intranet-reporting-indicators-drop.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

---------------------------------------------------
-- Drop Contents

-- Delete components and menus
select im_menu__del_module('intranet-reporting-indicators');
select im_component_plugin__del_module('intranet-reporting-indicators');

-- Delete any existing indicators.
create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
	row		RECORD;
begin
	FOR row IN
		select	indicator_id
		from	im_indicators
	LOOP
		PERFORM im_indicator__delete(row.indicator_id);
	END LOOP;
	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


---------------------------------------------------
-- Drop the data model

drop view im_indicator_sections;
drop function im_indicator__delete(integer);
drop function im_indicator__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, integer, integer, text,
        double precision, double precision, integer
);
drop function im_indicator__name(integer);
drop sequence im_indicator_results_seq;
drop table im_indicator_results;
drop table im_indicators;
delete from im_categories where category_type = 'Intranet Indicator Section';

-- Cleanup remaining rests in the database
delete from im_reports where report_id in (
	select	object_id
	from	acs_objects
	where	object_type = 'im_indicator'
);
delete from acs_objects where object_type = 'im_indicator';

-- Delete the object type itself.
SELECT acs_object_type__drop_type('im_indicator','f');

