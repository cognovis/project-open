--
--  Copyright (C) 2001, 2002 MIT
--
--  This file is part of dotLRN.
--
--  dotLRN is free software; you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software
--  Foundation; either version 2 of the License, or (at your option) any later
--  version.
--
--  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
--  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
--  details.
--

--
-- Creates the file-storage portlet
--
-- @author Arjun Sanyal(arjun@openforce.net)
-- @creation-date 2001-30-09
-- @version $Id: fs-portlet-create.sql,v 1.3 2004/07/24 08:34:22 jeffd Exp $
--
-- @author dan chak (chak@openforce.net)
-- ported to postgres 2002-07-09


SELECT im_component_plugin__new (
        null,                           -- plugin_id
        'acs_object',                   -- object_type
        now(),                          -- creation_date
        null,                           -- creation_user
        null,                           -- creation_ip
        null,                           -- context_id
        'Intranet FS Component',        -- plugin_name
        'intranet-fs',                  -- package_name
        'right',                        -- location
        '/intranet/projects/view',      -- page_url
        null,                           -- view_name
        10,                             -- sort_order
        'im_fs_component -user_id $user_id -project_id $project_id -return_url $return_url'
);