-- upgrade-3.4.0.7.6-3.4.0.7.7.sql

SELECT acs_log__debug('/packages/intranet-dynfield/sql/postgresql/upgrade/upgrade-3.4.0.7.6-3.4.0.7.7.sql','');

-- Make sure the default_payment_days show integer values.
update im_dynfield_widgets set deref_plpgsql_function = 'im_integer_from_id' where widget_name = 'integer';

