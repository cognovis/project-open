-- upgrade-3.2.10.0.0-3.2.11.0.0.sql

alter table im_invoices
add        discount_perc           numeric(12,2);
alter table im_invoices
add        discount_text	   text;
alter table im_invoices 
ALTER discount_perc set default 0;


alter table im_invoices
add        surcharge_perc          numeric(12,2);
alter table im_invoices
add        surcharge_text          text;
alter table im_invoices 
ALTER surcharge_perc set default 0;


alter table im_invoices
add	   deadline_start_date	timestamptz;

alter table im_invoices
add	   deadline_interval	interval;

