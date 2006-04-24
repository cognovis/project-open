

-- Rename the im_price_idx to im_timesheet_price_idx
drop index im_price_idx;


create unique index im_timesheet_price_idx on im_timesheet_prices (
        uom_id, company_id, task_type_id, material_id, currency
);

