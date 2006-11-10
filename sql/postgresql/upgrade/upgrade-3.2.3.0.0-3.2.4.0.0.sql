-- upgrade-3.2.3.0.0-3.2.4.0.0.sql

alter table im_hours
add cost_id integer;

alter table im_hours 
add constraint im_hours_cost_fk
foreign key (cost_id) references im_costs;

