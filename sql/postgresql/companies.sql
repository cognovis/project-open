

-- Get everything about a company
select
        c.*,
        o.*,
        cc.country_name
from
        im_companies c
      LEFT JOIN
        im_offices o ON c.main_office_id=o.office_id
      LEFT JOIN
        country_codes cc ON o.address_country_code=cc.iso
where
        c.company_id = :company_id
;


-- Update part of a company
update im_companies set
        company_name            = :company_name,
        company_path            = :company_path,
        company_status_id       = :company_status_id,
        company_type_id = :company_type_id,
        manager_id              = :manager_id,
        billable_p              = 'f',
        note                    = '',
        accounting_contact_id   = :freelance_id,
        primary_contact_id      = :freelance_id
where
        company_id = :company_id
