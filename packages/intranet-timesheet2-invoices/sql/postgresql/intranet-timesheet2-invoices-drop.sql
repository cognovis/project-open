-- /packages/intranet-timesheet2-invoices/sql/postgresql/intranet-timesheet2-invoices-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

select    im_component_plugin__del_module('intrane-timesheet2-invoices');
select    im_menu__del_module( 'intranet-timesheet2-invoices');


drop function  im_timesheet_prices_calc_relevancy (
       integer, integer, integer, integer, integer, integer
);


--
drop table im_timesheet_prices;

--
drop sequence im_timesheet_prices_seq;


--
drop function im_timesheet_invoice__name (integer);
drop function im_timesheet_invoice__delete (integer);
drop function im_timesheet_invoice__new (
        integer,        
        varchar,        
        timestamptz,    
        integer,
        varchar,        
        integer,        
        varchar,
        integer,
        integer,
        integer,        
        timestamptz,    
        char,           
        integer,        
        integer,        
        integer,        
        integer,        
        integer,        
        numeric,
        numeric,        
        numeric,        
        varchar         
);


---
drop table im_timesheet_invoices;


-- Now we can drop the object type
select acs_object_type__drop_type('im_timesheet_invoice', 'f');

