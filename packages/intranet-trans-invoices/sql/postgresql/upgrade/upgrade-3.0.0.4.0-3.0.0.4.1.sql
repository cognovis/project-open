-- upgrade from 3.0.0.4.0 to 3.0.0.4.1

SELECT acs_log__debug('/packages/intranet-trans-invoices/sql/postgresql/upgrade/upgrade-3.1.0.0.0-3.1.0.1.0.sql','');


ALTER TABLE im_trans_prices 
	ALTER COLUMN currency 
	SET not null;


ALTER TABLE im_trans_prices 
	ALTER COLUMN price
	SET not null;

