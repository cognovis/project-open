-- /packages/intranet-invoices/sql/postgresql/intranet-reporting-indicators-drop.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


select im_menu__del_module('intranet-reporting-indicators');
select im_component_plugin__del_module('intranet-reporting-indicators');
drop view im_indicator_sections;
drop function im_indicator__delete(integer);
drop function im_indicator__new (
        integer, varchar, timestamptz, integer, varchar, integer,
        varchar, varchar, integer, integer, text,
        double precision, double precision, integer
);
drop function im_indicator__name(integer);
drop sequence im_indicator_results_seq;
drop table im_indicator_results;
drop table im_indicators;
delete from im_categories where category_type = 'Intranet Indicator Section';
SELECT acs_object_type__delete_type('im_indicator');

