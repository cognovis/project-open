
-- Show timesheet tasks per project
select
        t.task_id,
        t.planned_units,
        t.billable_units,
        t.reported_hours_cache,
        t.task_name,
        t.uom_id,
        t.task_type_id,
        t.project_id,
        im_category_from_id(t.uom_id) as uom_name,
        im_category_from_id(t.task_type_id) as type_name,
        im_category_from_id(t.task_status_id) as task_status,
        p.project_name,
        p.project_path,
        p.project_path as project_short_name
from
        im_timesheet_tasks_view t,
        im_projects p
where
        $tasks_where_clause
        and t.project_id = p.project_id
order by
        project_id, task_id



-- Calculate the sum of tasks (distinct by TaskType and UnitOfMeasure)
-- and determine the price of each line using a custom definable
-- function.

select
        sum(t.planned_units) as planned_sum,
        sum(t.billable_units) as billable_sum,
        sum(t.reported_hours_cache) as reported_sum,
        t.task_type_id,
        t.uom_id,
        p.company_id,
        p.project_id,
        t.material_id
from
        im_timesheet_tasks_view t,
        im_projects p
where
        $tasks_where_clause
        and t.project_id=p.project_id
group by
        t.material_id,
        t.task_type_id,
        t.uom_id,
        p.company_id,
        p.project_id
;



--  Calculate the price for the specific service.
--  Complicated undertaking, because the price depends on a number of variables,
--  depending on client etc. As a solution, we act like a search engine, return
--  all prices and rank them according to relevancy. We take only the first
--  (=highest rank) line for the actual price proposal.
-- 
select
        p.relevancy as price_relevancy,
        trim(' ' from to_char(p.price,:number_format)) as price,
        p.company_id as price_company_id,
        p.uom_id as uom_id,
        p.task_type_id as task_type_id,
        p.material_id as material_id,
        p.valid_from,
        p.valid_through,
        c.company_path as price_company_name,
        im_category_from_id(p.uom_id) as price_uom,
        im_category_from_id(p.task_type_id) as price_task_type,
        im_category_from_id(p.material_id) as price_material
from
        (
                (select
                        im_timesheet_prices_calc_relevancy (
                                p.company_id,:company_id,
                                p.task_type_id, :task_type_id,
                                p.material_id, :material_id
                        ) as relevancy,
                        p.price,
                        p.company_id,
                        p.uom_id,
                        p.task_type_id,
                        p.material_id,
                        p.valid_from,
                        p.valid_through
                from im_timesheet_prices p
                where
                        uom_id=:uom_id
                        and currency=:invoice_currency
                )
        ) p,
        im_companies c
where
        p.company_id=c.company_id
        and relevancy >= 0
order by
        p.relevancy desc,
        p.company_id,
        p.uom_id






