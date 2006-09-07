-- /packages/intranet-cost/sql/postgres/upgrade/upgrade-3.1.4.0.0-3.2.0.0.0.sql
--
-- Project/Open Cost Core
-- 040207 frank.bergmann@project-open.com
--
-- Copyright (C) 2004 Project/Open
--
-- All rights including reserved. To inquire license terms please 
-- refer to http://www.project-open.com/modules/<module-key>

-------------------------------------------------------------
-- 
---------------------------------------------------------

-- Add cache fields for expenses

alter table im_projects add     cost_expense_planned_cache	numeric(12,2);
alter table im_projects alter	cost_expense_planned_cache	set default 0;

alter table im_projects add     cost_expense_logged_cache	numeric(12,2);
alter table im_projects alter	cost_expense_logged_cache	set default 0;




INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3720,'Expense Item','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3722,'Expense Report','Intranet Cost Type');
INSERT INTO im_categories (CATEGORY_ID, CATEGORY, CATEGORY_TYPE)
VALUES (3724,'Delivery Note','Intranet Cost Type');

create or replace function im_payments_audit_tr () returns opaque as '
begin
        insert into im_payments_audit (
               payment_id,
               cost_id,
               company_id,
               provider_id,
               received_date,
               start_block,
               payment_type_id,
               payment_status_id,
               amount,
               currency,
               note,
               last_modified,
               last_modifying_user,
               modified_ip_address
        ) values (
               old.payment_id,
               old.cost_id,
               old.company_id,
               old.provider_id,
               old.received_date,
               old.start_block,
               old.payment_type_id,
               old.payment_status_id,
               old.amount,
               old.currency,
               old.note,
               old.last_modified,
               old.last_modifying_user,
               old.modified_ip_address
        );
        return new;
end;' language 'plpgsql';



-- 060720 Frank Bergmann: Does work!
--
create trigger im_payments_audit_tr
before update or delete on im_payments
for each row execute procedure im_payments_audit_tr ();

