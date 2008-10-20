-- upgrade-3.4.0.3.0-3.4.0.3.1.sql

-- compatibility for WF calls
CREATE OR REPLACE FUNCTION im_biz_object__set_status_id (integer, varchar, integer) RETURNS integer AS '
DECLARE
	p_object_id		alias for $1;
	p_dummy			alias for $2;
	p_status_id		alias for $3;
BEGIN
	return im_biz_object__set_status_id (p_object_id, p_status_id::integer);
END;' language 'plpgsql';


-- Milestone project type.
SELECT im_category_new (2504, 'Milestone', 'Intranet Project Type');
update im_categories set enabled_p = 'f' 
where	category = 'Milestone' and
	category_type = 'Intranet Project Type';


-- Fix DynField issue with database "float"
insert into acs_datatypes (datatype) values ('float');




