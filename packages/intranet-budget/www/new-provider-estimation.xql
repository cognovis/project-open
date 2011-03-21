<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="invoice_item">
    <querytext>
	select
		i.*,
		p.project_name,
		p.project_nr as project_short_name,
		im_category_from_id(i.item_uom_id) as item_uom,
		im_category_from_id(i.item_type_id) as item_type,
		im_material_name_from_id(i.item_material_id) as item_material
	from
		im_invoice_items i
		LEFT JOIN im_projects p ON i.project_id=p.project_id
	where
		i.invoice_id = :invoice_id
	order by
		i.sort_order,
		i.project_id
    </querytext>
</fullquery>
  
</queryset>
