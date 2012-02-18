SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');


SELECT im_report_new (
	'Translation Price List Export',
	'translation_price_list_export',
	'intranet-trans-invoices',
	40,
	(select menu_id from im_menus where label = 'reporting-translation'),
	'
select
	im_category_from_id(tp.uom_id) as uom,
	c.company_path,
	im_category_from_id(tp.task_type_id) as task_type,
	im_category_from_id(tp.target_language_id) as target_language,
	im_category_from_id(tp.source_language_id) as source_language,
	im_category_from_id(tp.subject_area_id) as subject_area,
	im_category_from_id(tp.file_type_id) as file_type,
	tp.valid_from,
	tp.valid_through,
	replace(to_char(tp.price, ''99999.99''), ''.'', '','') as price,
	tp.currency
from	im_trans_prices tp,
	im_companies c
where	tp.company_id = c.company_id and
	tp.company_id = %company_id%
order by
	im_category_from_id(tp.uom_id),
	c.company_path,
	im_category_from_id(tp.task_type_id),
	im_category_from_id(tp.target_language_id),
	im_category_from_id(tp.source_language_id),
	im_category_from_id(tp.subject_area_id),
	im_category_from_id(tp.file_type_id)
'
);

