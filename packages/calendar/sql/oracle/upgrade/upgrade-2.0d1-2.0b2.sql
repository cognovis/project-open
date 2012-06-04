--
-- Set the context ID of existing calendars to the package_id
--
-- @cvs-id $Id$
--

-- AG: The fancy update...from syntax in the PG version is not compatible with
-- either ora8 or ora9.

begin
  for cur in (select o.object_id, c.package_id from acs_objects o, calendars c where o.object_id = c.calendar_id) loop
    update acs_objects set context_id = cur.package_id where object_id = cur.object_id;
  end loop;
end;
/
show errors;

