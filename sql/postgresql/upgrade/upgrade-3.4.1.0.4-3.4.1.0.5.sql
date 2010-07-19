-- upgrade-3.4.1.0.4-3.4.1.0.5.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.1.0.4-3.4.1.0.5.sql','');


CREATE OR REPLACE VIEW ams_attributes as
	select	aa.*,
		da.attribute_id as dynfield_attribute_id,
		da.acs_attribute_id,
		da.widget_name as widget,
		da.already_existed_p,
		da.deprecated_p
	from
		acs_attributes aa
		LEFT JOIN im_dynfield_attributes da ON (aa.attribute_id = da.acs_attribute_id)
;

