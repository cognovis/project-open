--
-- Set the context ID of existing calendars to the package_id
--
-- @cvs-id $Id$
--


update acs_objects
set    context_id = package_id
from   calendars
where  calendar_id = object_id;
