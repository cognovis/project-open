-- upgrade-4.0.0.0.0-4.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-cust-koernigweber/sql/postgresql/upgrade/upgrade-4.0.0.0.0-4.0.0.0.1.sql','');

create or replace function inline_0 ()
returns integer as '
declare
        v_count         integer;
begin
        select count(*) into v_count from information_schema.columns where
              table_name = ''im_customer_prices''
              and column_name = ''start_date'';

        IF v_count > 0 THEN return 1; END IF;

        alter table im_customer_prices add column start_date timestamptz;
        RETURN 0;

end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

-- drop constraint 
ALTER TABLE im_customer_prices DROP CONSTRAINT im_customer_prices_user_id_key;

-- Create new constraint 
create unique index im_customer_prices_user_id_key on im_customer_prices (user_id, object_id, project_type_id, start_date);

-- adding start_date
create or replace function im_employee_customer_price__update(int4,varchar,timestamptz,int4,varchar,int4,int4,int4,numeric,varchar,int4,timestamptz) returns int4 as '
                DECLARE
                        p_id              alias for $1;
                        p_object_type     alias for $2;
                        p_creation_date   alias for $3;
                        p_creation_user   alias for $4;
                        p_creation_ip     alias for $5;
                        p_context_id      alias for $6;

                        p_user_id         alias for $7;
                        p_object_id       alias for $8;
                        p_amount          alias for $9;
                        p_currency        alias for $10;
                        p_cost_object_category_id alias for $11;
			p_start_date	  alias for $12;

                        v_id              integer;
                        v_count           integer;
                BEGIN
                        RAISE NOTICE ''im_employee_customer_price__update: user_id: %; object_id: %; project_type_id:%; '', p_user_id, p_object_id, p_cost_object_category_id;
		        IF p_cost_object_category_id IS NULL THEN
			        RAISE NOTICE ''im_employee_customer_price__update: p_cost_object_category_id IS NULL'';
			        select count(*) into v_count from im_customer_prices where user_id = p_user_id and object_id = p_object_id and project_type_id IS NULL and start_date = p_start_date;
		        ELSE
			        RAISE NOTICE ''im_employee_customer_price__update: p_cost_object_category_id IS NOT NULL'';
			        select count(*) into v_count from im_customer_prices where user_id = p_user_id and object_id = p_object_id and cost_object_category_id = p_cost_object_category_id and start_date = p_start_date;
		        END IF;

		        RAISE NOTICE ''im_employee_customer_price__update: Count: %'', v_count;

                        IF v_count > 0 THEN
			        IF p_cost_object_category_id IS NULL THEN
				        update im_customer_prices set amount = p_amount where object_id = p_object_id and user_id = p_user_id and project_type_id IS NULL;
			        ELSE
				        update im_customer_prices set amount = p_amount where object_id = p_object_id and user_id = p_user_id and cost_object_category_id = p_cost_object_category_id;
			        END IF;
		        ELSE
                                v_id := acs_object__new (
                                        p_id,
                                        p_object_type,
                                        p_creation_date,
                                        p_creation_user,
                                        p_creation_ip,
                                        p_context_id
                                );

                                insert into im_customer_prices (
                                        id, user_id, object_id, amount, currency, cost_object_category_id, start_date
                                ) values (
                                        v_id, p_user_id, p_object_id, p_amount, p_currency, p_cost_object_category_id, p_start_date
                                );
                        END IF;
                        return v_id;
end;' language 'plpgsql';
