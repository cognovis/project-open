-- 
-- packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d11-0.2d12.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2011-06-22
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-budget/sql/postgresql/upgrade/upgrade-0.2d11-0.2d12.sql','');

-- create dynfield attributes approved_p
-- Refresh the view afterwards

CREATE OR REPLACE FUNCTION inline_0 ()
RETURNS integer AS '
DECLARE
	v_acs_attribute_id	integer;
	v_attribute_id		integer;
	v_count			integer;
	row			record;
BEGIN

    
 	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_budget'' AND attribute_name = ''approved_p'';
   	IF v_acs_attribute_id IS NULL THEN
        alter table im_budgets add column approved_p boolean default ''f'';
        PERFORM im_dynfield_attribute_new (''im_budget'', ''approved_p'', ''#intranet-budget.Approved#'', ''checkbox'', ''boolean'', ''f'', 20, ''f'');
        PERFORM content_type__refresh_view(''im_budget'');
    END IF;

 	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_budget_hour'' AND attribute_name = ''approved_p'';
   	IF v_acs_attribute_id IS NULL THEN
        alter table im_budget_hours add column approved_p boolean default ''f'';
        PERFORM im_dynfield_attribute_new (''im_budget_hour'', ''approved_p'', ''#intranet-budget.Approved#'', ''checkbox'', ''boolean'', ''f'', 20, ''f'');
        PERFORM content_type__refresh_view(''im_budget_hour'');
    END IF;

 	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_budget_cost'' AND attribute_name = ''approved_p'';
   	IF v_acs_attribute_id IS NULL THEN
        alter table im_budget_costs add column approved_p boolean default ''f'';
        PERFORM im_dynfield_attribute_new (''im_budget_cost'', ''approved_p'', ''#intranet-budget.Approved#'', ''checkbox'', ''boolean'', ''f'', 20, ''f'');
        PERFORM content_type__refresh_view(''im_budget_cost'');
    END IF;

 	SELECT attribute_id INTO v_acs_attribute_id FROM acs_attributes WHERE object_type = ''im_budget_benefit'' AND attribute_name = ''approved_p'';
   	IF v_acs_attribute_id IS NULL THEN
        alter table im_budget_benefits add column approved_p boolean default ''f'';
        PERFORM im_dynfield_attribute_new (''im_budget_benefit'', ''approved_p'', ''#intranet-budget.Approved#'', ''checkbox'', ''boolean'', ''f'', 20, ''f'');
        PERFORM content_type__refresh_view(''im_budget_benefit'');
    END IF;
    
    -- Update the current live versions with the approved flag

    update im_budgets set approved_p = ''t'' where budget_id in (select live_revision from cr_items where content_type = ''im_budget'');
    update im_budget_hours set approved_p = ''t'' where hour_id in (select live_revision from cr_items where content_type = ''im_budget_hour'');
    update im_budget_costs set approved_p = ''t'' where fund_id in (select live_revision from cr_items where content_type = ''im_budget_cost'');
    update im_budget_benefits set approved_p = ''t'' where fund_id in (select live_revision from cr_items where content_type = ''im_budget_benefit'');

	RETURN 0;
END;' language 'plpgsql';

SELECT inline_0 ();
DROP FUNCTION inline_0 ();

