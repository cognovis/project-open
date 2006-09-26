-------------------------------------------------------------
-- Cost Components
--

select im_component_plugin__del_module('intranet-cost');

-- Show the finance component in a projects "Finance" page
--
select  im_component_plugin__new (
	null,				 -- plugin_id
	'acs_object',			 -- object_type
	now(),				 -- creation_date
	null,				 -- creation_user
	null,				 -- creation_ip
	null,				 -- context_id

	'Project Finance Component',	 -- plugin_name
	'intranet-cost',		 -- package_name
	'finance',			 -- location
	'/intranet/projects/view',	 -- page_url
	null,				 -- view_name
	50,				 -- sort_order
	'im_costs_project_finance_component $user_id $project_id'  -- component_tcl
    );


