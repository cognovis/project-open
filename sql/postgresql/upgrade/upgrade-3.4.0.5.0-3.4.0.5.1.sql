-- upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');


update im_categories set
	enabled_p = 'f'
where
	category = 'lightgreen' and
	category_type = 'Intranet Skin';

