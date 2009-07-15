-- upgrade-3.4.0.7.1-3.4.0.7.2.sql

SELECT acs_log__debug('/packages/intranet-cost/sql/postgresql/upgrade/upgrade-3.4.0.7.1-3.4.0.7.2.sql','');


alter table im_costs 
add column vat_type_id	integer
			constraint im_cost_vat_type_fk
			references im_categories
;
