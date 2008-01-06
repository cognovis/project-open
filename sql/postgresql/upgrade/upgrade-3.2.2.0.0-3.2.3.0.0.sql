-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.2.2.0.0-3.2.3.0.0.sql
--
-- Copyright (C) 2006 Project/Open
--
-- All rights including reserved. To inquire license terms please
-- refer to http://www.project-open.com/modules/<module-key>

-- (re-) create to make sure the drop works
create or replace view im_cost_type as
select  category_id as cost_type_id,
        category as cost_type
from    im_categories
where   category_type = 'Intranet Cost Type';

drop view im_cost_types;

create or replace view im_cost_types as
select  category_id as cost_type_id,
        category as cost_type,
        CASE
            WHEN category_id = 3700 THEN 'fi_read_invoices'
            WHEN category_id = 3702 THEN 'fi_read_quotes'
            WHEN category_id = 3704 THEN 'fi_read_bills'
            WHEN category_id = 3706 THEN 'fi_read_pos'
            WHEN category_id = 3716 THEN 'fi_read_repeatings'
            WHEN category_id = 3718 THEN 'fi_read_timesheets'
            WHEN category_id = 3720 THEN 'fi_read_expense_items'
            WHEN category_id = 3722 THEN 'fi_read_expense_bundles'
            WHEN category_id = 3724 THEN 'fi_read_delivery_notes'
            ELSE 'fi_read_all'
        END as read_privilege,
        CASE
            WHEN category_id = 3700 THEN 'fi_write_invoices'
            WHEN category_id = 3702 THEN 'fi_write_quotes'
            WHEN category_id = 3704 THEN 'fi_write_bills'
            WHEN category_id = 3706 THEN 'fi_write_pos'
            WHEN category_id = 3716 THEN 'fi_write_repeatings'
            WHEN category_id = 3718 THEN 'fi_write_timesheets'
            WHEN category_id = 3720 THEN 'fi_write_expense_items'
            WHEN category_id = 3722 THEN 'fi_write_expense_bundles'
            WHEN category_id = 3724 THEN 'fi_write_delivery_notes'
            ELSE 'fi_write_all'
        END as write_privilege,
        CASE
            WHEN category_id = 3700 THEN 'invoice'
            WHEN category_id = 3702 THEN 'quote'
            WHEN category_id = 3704 THEN 'bill'
            WHEN category_id = 3706 THEN 'po'
            WHEN category_id = 3716 THEN 'repcost'
            WHEN category_id = 3718 THEN 'timesheet'
            WHEN category_id = 3720 THEN 'expitem'
            WHEN category_id = 3722 THEN 'expbundle'
            WHEN category_id = 3724 THEN 'delnote'
            ELSE 'unknown'
        END as short_name
from    im_categories
where   category_type = 'Intranet Cost Type';

