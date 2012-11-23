
set html [im_ad_hoc_query -format html "

select	
	im_company__name(customer_id) as customer_name,
	im_name_from_user_id(user_id) as user,
	type,
	count(*) as cnt,
	sum(amount) as amount
from	(
	select	CASE
			WHEN c.cost_type_id=3700 THEN 'im_invoice'
			WHEN c.cost_type_id=3702 THEN 'im_quote'
		END as type,
		c.customer_id as customer_id,
		o.creation_user as user_id,
		c.effective_date::date as date,
		c.amount
	from	im_costs c,
		acs_objects o
	where	c.cost_id = o.object_id and
		c.effective_date > now()::date - 90 and
		c.cost_type_id in (3700, 3702)
UNION
	select	o.object_type as type,
		p.company_id as customer_id,
		o.creation_user as user_id,
		o.creation_date::date as date,
		400 as amount
	from	im_projects p,
		acs_objects o
	where	p.project_id = o.object_id and
		o.creation_date > now()::date - 90
UNION
	select	'im_forum_topic' as type,
		p.company_id as customer_id,
		ft.owner_id as user_id,
		ft.posting_date::date as date,
		1000 as amount
	from	im_forum_topics ft,
		im_projects p
	where	ft.object_id = p.project_id and
		ft.posting_date > now()::date - 90
UNION
	select	'im_hour' as type,
		p.company_id as customer_id,
		h.user_id,
		h.day::date as date,
		h.hours * 30.0 as amount
	from	im_hours h,
		im_projects p
	where	h.project_id = p.project_id and
		h.day > now()::date - 90
UNION
	select	o.object_type as type,
		r.object_id_one as customer_id,
		o.creation_user as user_id,
		o.creation_date::date as date,
		100 as amount
	from	acs_rels r,
		acs_objects o,
		im_companies c
	where	r.rel_id = o.object_id and
		r.object_id_one = c.company_id and
		o.creation_date > now()::date - 90
UNION
	select	o.object_type as type,
		r.object_id_two as customer_id,
		o.creation_user as user_id,
		o.creation_date::date as date,
		100 as amount
	from	acs_rels r,
		acs_objects o,
		im_companies c
	where	r.rel_id = o.object_id and
		r.object_id_two = c.company_id and
		o.creation_date > now()::date - 90
UNION
	select	o.object_type as type,
		p.company_id as customer_id,
		o.creation_user as user_id,
		o.creation_date::date as date,
		1 as amount
	from	acs_rels r,
		acs_objects o,
		im_projects p
	where	r.rel_id = o.object_id and
		r.object_id_one = p.project_id and
		o.creation_date > now()::date - 90
UNION
	select	o.object_type as type,
		p.company_id as customer_id,
		o.creation_user as user_id,
		o.creation_date::date as date,
		1 as amount
	from	acs_rels r,
		acs_objects o,
		im_projects p
	where	r.rel_id = o.object_id and
		r.object_id_two = p.project_id and
		o.creation_date > now()::date - 90
	) t
group by
	t.type,
	t.customer_id,
	t.user_id
order by 
	t.customer_id,
	t.user_id
"]

doc_return 200 "text/html" "
[im_header ""]
$html
[im_footer]
"