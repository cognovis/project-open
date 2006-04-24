

-- Rename the im_price_idx to im_trans_price_idx

drop index im_price_idx;

create unique index im_trans_price_idx on im_trans_prices (
        uom_id, company_id, task_type_id, target_language_id,
        source_language_id, subject_area_id, currency
);

