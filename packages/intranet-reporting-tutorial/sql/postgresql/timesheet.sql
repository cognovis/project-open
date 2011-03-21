------------------------------------------------------------
-- Timesheet
------------------------------------------------------------

-- Get the hours spent by everybody on a particular project
select
	email, 
	sum(im.hours) as hours
from 
	im_hours im, 
	users u
where
	im.user_id = u.user_id
	and im.user_id = :user_id
	and im.on_what_id = :project_id
	and im.day between 
		to_date('$from_date(date)',:date_format) 
	and to_date('$to_date(date)',:date_format)
group by email;


-- Get the hours on one particular user on all projects
SELECT
	p.project_id,
	p.project_name,
	sum(h.hours) as total
FROM
	im_hours h,
	im_projects p
WHERE
	p.project_id = h.project_id
	AND h.day >= trunc( to_date( :start_date, 'MM/DD/YYYY' ),'Day' )
	AND h.day < trunc( to_date( :end_date, 'MM/DD/YYYY' ),'Day' ) + 1
	AND h.user_id = :user_id
GROUP BY p.project_id, p.project_name
;


-- Find the list of users who have logged _some_ hours
-- between from_date and to_date.
select 
	email, 
	im.user_id as id_of_user
from
	im_hours im, 
	users u
where 
	im.user_id = u.user_id
	and im.day between 
		to_date('$from_date(date)',:date_format) 
		and to_date('$to_date(date)',:date_format)
group by 
	email, im.user_id
order by email
;


-- Show hours logged on the project hierarchy(!).
-- This query also allows you to aggregate hours.
select
	h.hours,
	h.note,
	h.billing_rate,
	parent.project_id as top_project_id,
	children.project_id as project_id,
	children.project_nr as project_nr,
	children.project_name as project_name,
	children.parent_id as parent_project_id,
	children.project_status_id as project_status_id,
	im_category_from_id(children.project_status_id) as project_status,
	parent.project_nr as parent_project_nr,
	parent.project_name as parent_project_name,
	tree_level(children.tree_sortkey) -1 as subproject_level
from
	im_projects parent,
	im_projects children
	left outer join (
			select  *
			from    im_hours h
			where   h.day = to_date(:julian_date, 'J')
				and h.user_id = :user_id
		) h
		on (h.project_id = children.project_id)
where
	children.tree_sortkey between
		parent.tree_sortkey and
		tree_right(parent.tree_sortkey)
	and parent.project_id in (
	    $project_sql
	)
order by
	lower(parent.project_name),
	children.tree_sortkey;


-- Insert a new timesheet item
insert into im_hours (
	user_id, project_id,
	day, hours,
	billing_rate, billing_currency,
	note
) values (
	:user_id, :project_id,
	to_date(:julian_date,'J'), :hours_worked,
	:billing_rate, :billing_currency,
	:note
);

-- After inserting a timesheet item you need to 
-- create an im_cost item to reflect the cost.
-- This query checks if there is a cost item already
-- related to the timesheet item. 
-- Make sure there is only one cost_item selected.
-- This should always be the case, but there may be
-- inconsistencies in the DB due to manual entries etc...
--
select
	cost_id
from
	im_costs
where
	cost_type_id = [im_cost_type_timesheet]
	and project_id = :project_id
	and effective_date = to_date(:julian_date, 'J')
;

-- Update a timesheet item
-- Determining the cost_center_id for each user is a bit complicated,
-- it's better to do this in TCL using:
-- set cost_center_id [im_costs_default_cost_center_for_user $user_id]
--
update  im_costs set
	cost_name	       = :cost_name,
	project_id	      = :project_id,
	cost_center_id	  = :cost_center_id,
	customer_id	     = :customer_id,
	effective_date	  = to_date(:julian_date, 'J'),
	amount		  = :billing_rate * cast(:hours_worked as numeric),
	currency		= :billing_currency,
	payment_days	    = 0,
	vat		     = 0,
	tax		     = 0,
	description	     = :note
where
	cost_id = :cost_id;


-- Delete a Timesheet item.
delete from im_hours
where	user_id = :user_id
	and project_id = :project_id
	and day = to_date(:julian_date, 'J')
;

-- We also need to delete the related im_cost items.
DECLARE
	row RECORD;
BEGIN
	for row in
		select  cost_id
		from    im_costs
		where   cost_type_id = [im_cost_type_timesheet]
			and project_id = :project_id
			and effective_date = to_date(:julian_date, 'J')
	loop
		PERFORM im_cost__delete(row.cost_id);
	end loop;
	return 0;
END;


-- Update reported_hours_cache in the im_projects table.
-- This is necessary because calculating a sum over all
-- timesheet items can be very(!) expense.
-- A bit ugly, but this is why the field has the postfix
-- "_cache".
update im_projects
set reported_hours_cache = (
	select  sum(h.hours)
	from    im_hours h
	where   h.project_id = :project_id
)
where project_id = :project_id;


------------------------------------------------------------
-- Hours
--
-- We record logged hours of both project and client related work
--

create table im_hours (
	user_id			integer 
				constraint im_hours_user_id_nn
				not null 
				constraint im_hours_user_id_fk
				references users,
	project_id		integer 
				constraint im_hours_project_id_nn
				not null 
				constraint im_hours_project_id_fk
				references im_projects,
	day			timestamptz,
	hours			numeric(5,2),
				-- ArsDigita/ACS billing system - log prices with hours
	billing_rate		numeric(5,2),
	billing_currency	char(3)
				constraint im_hours_billing_currency_fk
				references currency_codes(iso),
	note			varchar(4000)
);
