-- /packages/intranet-timesheet2-invoices/sql/oracle/intranet-timesheet2-invoices-create.sql
--
-- Copyright (c) 2003-2004 Project/Open
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Timesheet Invoicing for Project/Open
--
-- Defines:
--	im_trans_prices			List of prices with defaults
--


-- Add links to edit im_timesheet_invoices objects...
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_invoice','view','/intranet-invoices/view?invoice_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_timesheet_invoice','edit','/intranet-invoices/new?invoice_id=');


