-- upgrade-3.2.10.0.0-3.2.11.0.0.sql


alter table im_trans_prices
add        file_type_id            integer
                                constraint im_trans_prices_file_type_fk
                                references im_categories
;


