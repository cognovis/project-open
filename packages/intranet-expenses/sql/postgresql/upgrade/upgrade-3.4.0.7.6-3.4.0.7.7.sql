-- upgrade-3.4.0.7.6-3.4.0.7.7.sql

SELECT acs_log__debug('/packages/intranet-expenses/sql/postgresql/upgrade/upgrade-3.4.0.7.6-3.4.0.7.7.sql','');


-- Update __delete function to delete expense bundles
-- that are referenced by other expenses.

-- Delete a single expense_bundle by ID
create or replace function im_expense_bundle__delete (integer)
returns integer as '
DECLARE
	p_bundle_id		alias for $1;
begin
	-- Remove references to this bundle
	update im_expenses
	set bundle_id = NULL
	where bundle_id = p_bundle_id;

	-- Erase the im_expense_bundles entry
	delete from im_expense_bundles
	where bundle_id = p_bundle_id;

	-- Erase the object
	PERFORM im_cost__delete(p_bundle_id);
	return 0;
end' language 'plpgsql';
