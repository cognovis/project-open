-- upgrade-3.3.1.0.0-3.3.1.1.0.sql

alter table im_user_absences
add absense_status_id integer
constraint im_user_absences_status_fk
references im_categories;

