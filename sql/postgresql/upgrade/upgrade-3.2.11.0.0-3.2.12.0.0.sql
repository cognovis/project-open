-- upgrade-3.2.10.0.0-3.2.11.0.0.sql


alter table im_trans_prices add
        min_price               numeric(12,4)
;




