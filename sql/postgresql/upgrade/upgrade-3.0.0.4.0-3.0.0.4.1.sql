-- upgrade from 3.0.0.4.0 to 3.0.0.4.1


ALTER TABLE im_trans_prices 
	ALTER COLUMN currency 
	SET not null;


ALTER TABLE im_trans_prices 
	ALTER COLUMN price
	SET not null;

