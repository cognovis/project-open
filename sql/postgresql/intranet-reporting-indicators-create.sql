-- /package/intranet-reporting-indicators/sql/postgresql/intranet-reporting-indicators-create.sql
--
-- Copyright (c) 2003-2007 ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author frank.bergmann@project-open.com


-----------------------------------------------------------
-- Store results of evaluating indicators
--

create sequence im_reporting_indicator_results_seq;

create table im_reporting_indicator_results (
	result_id		integer
				constraint im_reporting_indires_pk
				primary key,
	indicator_id		integer
				constraint im_reporting_indires_indicator_nn
				not null
				constraint im_reporting_indires_indicator_fk
				references im_reports,
	result_date		timestamptz,
	result			double precision
);


alter table im_reporting_indicator_results add
        constraint im_reporting_indires_un
	unique(indicator_id, result_date);


