-- /packages/intranet-forum/sql/oracle/intranet-forum-sc-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author pepels@gmail.com

-----------------------------------------------------------
-- Tasks, Incidents, News and Discussions (TIND)
--
-- ftscontenprovider support for content in intranet-core
-----------------------------------------------------------
-- Topics
--

select acs_sc_impl__new(
	   'FtsContentProvider',		-- impl_contract_name 
           'im_project',			-- impl_name (object in which we are going to search)
	   'projects'				-- impl_owner_name(just a silly parameter?)
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'im_project',        		-- impl_name
	   'datasource',			-- impl_operation_name
	   'projects__datasource', 	    	-- impl_alias
	   'TCL'				-- impl_pl
);

select acs_sc_impl_alias__new(
           'FtsContentProvider',		-- impl_contract_name
           'im_project',        		-- impl_name
	   'url',				-- impl_operation_name
	   'projects__url',			-- impl_alias
	   'TCL'				-- impl_pl
);


create function projects__itrg ()
returns trigger as '
begin
    perform search_observer__enqueue(new.project_id,''INSERT'');
    return new;
end;' language 'plpgsql';

create function projects__dtrg ()
returns trigger as '
begin
    perform search_observer__enqueue(old.project_id,''DELETE'');
    return old;
end;' language 'plpgsql';

create function projects__utrg ()
returns trigger as '
begin
    perform search_observer__enqueue(old.project_id,''UPDATE'');
    return old;
end;' language 'plpgsql';


create trigger projects__itrg after insert on im_projects
for each row execute procedure projects__itrg (); 

create trigger projects__dtrg after delete on im_projects
for each row execute procedure projects__dtrg (); 

create trigger projects__utrg after update on im_projects
for each row execute procedure projects__utrg (); 

