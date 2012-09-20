-- /packages/intranet-trans-invoices/sql/oracle/intranet-trans-invoices-drop.sql
--
-- Copyright (c) 2003-2004 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es


delete from im_reports where report_menu_id in (select menu_id from im_menus where package_name = 'intranet-trans-invoices');

select    im_component_plugin__del_module('intranet-trans-invoices');
select    im_menu__del_module( 'intranet-trans-invoices');


create or replace function inline_01 ()
returns integer as '
DECLARE
    v_menu_id           integer;
BEGIN
        select menu_id  into v_menu_id
        from im_menus
        where label = ''new_trans_invoice'';
        PERFORM im_menu__delete(v_menu_id);

        select menu_id  into v_menu_id
        from im_menus
        where label = ''project_pos'';
        PERFORM im_menu__delete(v_menu_id);

    return 0;
end;' language 'plpgsql';
select inline_01 ();
drop function inline_01 ();





delete from im_view_columns where view_id = 195;
delete from im_views where view_id = 195;
delete from im_view_columns where column_id > 19500 and column_id < 19599;



drop function im_file_type_from_trans_task (integer);
drop function im_trans_prices_calc_relevancy (
     integer, integer, integer, integer, integer, integer, integer, integer, integer, integer
);

drop function im_trans_prices_calc_relevancy (
     integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer
);

drop function im_trans_invoice__new (
        integer,        -- default null
        varchar,        -- default im_trans_invoice
        timestamptz,    -- default now()
        integer,
        varchar,        -- default null
        integer,        -- default null
        varchar,
        integer,
        integer,
        integer,        -- default null
        timestamptz,    -- default now()
        char,           -- default EUR
        integer,        -- default null
        integer,        -- default 602
        integer,        -- default 700
        integer,        -- default null
        integer,        -- default 30
        numeric,
        numeric,        -- default 0
        numeric,        -- default 0
        varchar         -- default null
);


drop function im_trans_invoice__delete (integer);
drop function im_trans_invoice__name (integer);




-- delete all im_trans_invoices without
-- deleting the rest of all invoices...
create or replace function inline_02 ()
returns integer as '
declare
	row RECORD;
begin
     for row in 
	select	invoice_id
	from	im_trans_invoices
     loop
	PERFORM im_trans_invoice__delete(row.invoice_id);
     end loop;
    return 0;
end;' language 'plpgsql';
select inline_02 ();
drop function inline_02 ();



-- delete links to edit im_trans_invoices objects...
delete from im_biz_object_urls where object_type = 'im_trans_invoice';

-- drop main table and object_type
drop table im_trans_invoices;

drop sequence im_trans_prices_seq;
drop table im_trans_prices;


delete from im_categories where category_type = 'Intranet Translation File Type';




-- ---------------------------------------------
-- Delete translation invoices completely before 
-- dropping the acs-objects
--
delete from im_invoice_items 
where invoice_id in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;

delete from im_invoices 
where invoice_id in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;

delete from im_payments 
where cost_id in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;


delete from im_costs 
where cost_id in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;

delete from acs_rels
where object_id_one in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;

delete from acs_rels
where object_id_two in (
	select object_id 
	from acs_objects 
	where object_type = 'im_trans_invoice'
	)
;

delete from acs_objects 
where object_type = 'im_trans_invoice';


delete from acs_object_type_tables where object_type = 'im_trans_invoice';
delete from im_biz_object_urls where object_type = 'im_trans_invoice';
-- Now we can drop the object type
select acs_object_type__drop_type('im_trans_invoice', 'f');

