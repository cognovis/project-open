-- upgrade-4.0.4.0.0-4.0.4.0.1.sql

SELECT acs_log__debug('/packages/intranet-riskmanagement/sql/postgresql/upgrade/upgrade-4.0.4.0.0-4.0.4.0.1.sql','');


create or replace view im_risk_status as
select	category_id as risk_status_id, category as risk_status
from	im_categories
where	category_type = 'Intranet Risk Status'
	and enabled_p = 't';

create or replace view im_risk_types as
select	category_id as risk_type_id, category as risk_type
from	im_categories
where	category_type = 'Intranet Risk Type'
	and enabled_p = 't';




-- Make sure all dynfield-attribute-map entries are set to EDIT
create or replace function inline_0 ()
returns integer as $body$
declare
	risk_type_row		RECORD;
	attribute_id_row	RECORD;
	exists_p		integer;
BEGIN
	FOR risk_type_row IN
		select risk_type_id from im_risk_types
	LOOP
		RAISE NOTICE 'risk_type=%', risk_type_row.risk_type_id;

		FOR attribute_id_row IN
			select	attribute_id 
			from	im_dynfield_attributes
			where	acs_attribute_id in (
				select	attribute_id 
				from	acs_attributes
				where	object_type='im_risk' and 
					attribute_name in ('risk_impact', 'risk_probability_percent')
				)
		LOOP
			select	count(*) into exists_p
			from	im_dynfield_type_attribute_map
			where	attribute_id = attribute_id_row.attribute_id and
				object_type_id = risk_type_row.risk_type_id;

			IF 0 = exists_p THEN
				RAISE NOTICE 'INSERT: attribute_id=%', attribute_id_row.attribute_id;
				insert into im_dynfield_type_attribute_map 
				(attribute_id, object_type_id, display_mode) values 
				(attribute_id_row.attribute_id, risk_type_row.risk_type_id, 'edit');
			ELSE
				RAISE NOTICE 'UPDATE: attribute_id=%', attribute_id_row.attribute_id;
				update im_dynfield_type_attribute_map
				set display_mode = 'edit'
				where	attribute_id = attribute_id_row.attribute_id and
					object_type_id = risk_type_row.risk_type_id;
			END IF;
		END LOOP;
	END LOOP;

	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


