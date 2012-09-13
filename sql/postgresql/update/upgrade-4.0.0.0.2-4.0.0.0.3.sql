-- upgrade-4.0.0.0.2-4.0.0.0.3.sql

SELECT acs_log__debug('/packages/intranet-timesheet2-workflow/sql/postgresql/upgrade/upgrade-4.0.0.0.2-4.0.0.0.3.sql','');

SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'im_component_plugin',          -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Allocation Costs',         	-- plugin_name
        'intranet-cust-koernigweber',   -- package_name
        'right',                        -- location
        '/intranet/companies/view',     -- page_url
        null,                           -- view_name
        15,                             -- sort_order
        'im_price_list $company_id 0 0 $return_url "" "" ""' -- component_tcl
);

update im_component_plugins set title_tcl = 'lang::message::lookup "" intranet-cust-koernigweber.TitlePortletAllocationCosts "Allocation Costs"' where plugin_name = 'Allocation Costs';

-- Create privileges for managing allocation costs 
select acs_privilege__create_privilege('admin_allocation_costs','Admin Allocation Costs','Admin Allocation Costs');
select acs_privilege__add_child('admin', 'admin_allocation_costs');

select im_priv_create('admin_allocation_costs', 'P/O Admins');
select im_priv_create('admin_allocation_costs', 'Senior Managers');
select im_priv_create('admin_allocation_costs', 'Technical Office');

