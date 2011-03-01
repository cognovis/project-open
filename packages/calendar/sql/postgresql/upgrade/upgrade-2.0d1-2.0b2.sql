--
-- Set the context ID of existing calendars to the package_id
--
-- @cvs-id $Id: upgrade-2.0d1-2.0b2.sql,v 1.2 2003/12/11 21:39:59 jeffd Exp $
--


update acs_objects
set    context_id = package_id
from   calendars
where  calendar_id = object_id;
