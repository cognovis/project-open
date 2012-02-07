SELECT acs_log__debug('/packages/intranet-reporting-translation/sql/postgresql/upgrade/upgrade-4.0.3.0.0-4.0.3.0.1.sql','');


SELECT im_report_new (
	'Translation Units Sold by UoM and Language',
	'translation_units_sold_by_uom_and_language',
	'intranet-reporting-translation',
	40,
	(select menu_id from im_menus where label = 'reporting-translation'),
	'
select
        item_uom,
        source_language,
        target_language,
        sum(item_units) as item_units
from
        (select substring(im_category_from_id(m.source_language_id) from 1 for 2) as source_language,
                substring(im_category_from_id(m.target_language_id) from 1 for 2) as target_language,
                im_category_from_id(ii.item_uom_id) as item_uom,
                item_units
        from    im_invoice_items ii,
                im_materials m,
                im_costs c
        where   ii.item_material_id = m.material_id and
                ii.invoice_id = c.cost_id and
                c.cost_type_id = 3700
        ) ii
group by
      source_language,
      target_language,
      item_uom
order by
      item_uom,
      source_language,
      target_language
'
);	

