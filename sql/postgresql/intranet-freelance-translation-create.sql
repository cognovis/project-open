-- /packages/intranet-freelance-translation/sql/postgres/intranet-freelance-translation-create.sql
--
-- Copyright (c) 2003-2007 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-- Show the freelance list in member-add page
--
select im_component_plugin__new (
	null,			-- plugin_id
	'acs_object',		-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip
	null,			-- context_id
	'Translation Freelance List',	 -- plugin_name
	'intranet-freelance-translation',-- package_name
	'bottom',		-- location
	'/intranet/member-add',	-- page_url
	null,			-- view_name
	20,			-- sort_order
	'im_freelance_trans_member_select_component $object_id $return_url'
);


