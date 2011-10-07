-- /packages/intranet-freelance-invoices/sql/oracle/intranet-freelance-invoices-drop.sql
--
-- Copyright (c) 2003 - 2009 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com
-- @author juanjoruizx@yahoo.es

select    im_component_plugin__del_module('intranet-freelance-invoices');
select    im_menu__del_module( 'intranet-freelance-invoices');

