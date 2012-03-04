<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-cost/www/list-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-22 -->
<!-- @arch-tag dd0aa941-7721-4e1e-b2c6-95dfa87e9f25 -->
<!-- @cvs-id $Id$ -->

<queryset>
    <rdbms>
        <type>postgresql</type>
        <version>7.2</version>
    </rdbms>
  
    <fullquery name = "costs_info_query">
        <querytext>

select
	c.*,
	to_char(c.amount * (1 + coalesce(c.vat,0)/100 + coalesce(c.tax,0)/100), :cur_format) as amount_formatted,
	to_date(c.start_block, :date_format) as start_block_formatted,
	to_date(c.effective_date, :date_format) as effective_date_formatted,
	c.effective_date::date + c.payment_days as due_date_calculated,
	o.object_type,
	url.url as cost_url,
	ot.pretty_name as object_type_pretty_name,
	cust.company_name as customer_name,
	cust.company_path as customer_short_name,
	proj.project_nr,
	prov.company_name as provider_name,
	prov.company_path as provider_short_name,
	im_category_from_id(c.cost_status_id) as cost_status,
	im_category_from_id(c.cost_type_id) as cost_type,
        CASE c.cost_status_id = 3810 
                WHEN true THEN
			0
                ELSE
                        now()::date - c.effective_date::date + c.payment_days::integer
        END as overdue        
	$extra_select
from
	im_costs c 
	LEFT OUTER JOIN im_projects proj ON c.project_id=proj.project_id
	LEFT OUTER JOIN im_companies cust ON c.customer_id = cust.company_id
	LEFT OUTER JOIN im_companies prov ON c.provider_id = prov.company_id,
	acs_objects o,
	acs_object_types ot,
	(select * from im_biz_object_urls where url_type=:view_mode) url,
	(       select distinct
			cc.cost_center_id,
			ct.cost_type_id
		from    im_cost_centers cc,
			im_cost_types ct,
			acs_permissions p,
			party_approved_member_map m,
			acs_object_context_index c,
			acs_privilege_descendant_map h
		where
			p.object_id = c.ancestor_id
			and h.descendant = ct.read_privilege
			and c.object_id = cc.cost_center_id
			and m.member_id = :user_id
			and p.privilege = h.privilege
			and p.grantee_id = m.party_id
	) cc
	$extra_from
where
	c.cost_id = o.object_id
	and o.object_type = url.object_type
	and o.object_type = ot.object_type
	and c.cost_center_id = cc.cost_center_id
	and c.cost_type_id = cc.cost_type_id
	$company_where
	$where_clause
	$extra_where
$order_by_clause

         </querytext>
    </fullquery>
</queryset>
