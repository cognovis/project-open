-- /packages/intranet-trans-invoices/sql/oracle/intranet-trans-invoices-create.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com

-- Translation Invoicing
--
-- Defines:
--	im_trans_prices			List of prices with defaults
--


-- Add links to edit im_trans_invoices objects...
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_invoice','view','/intranet-invoices/view?invoice_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'im_trans_invoice','edit','/intranet-invoices/new?invoice_id=');


