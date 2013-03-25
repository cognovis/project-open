-- upgrade-4.0.3.5.2-4.0.3.5.3.sql
SELECT acs_log__debug('/packages/intranet-core/sql/postgresql/upgrade/upgrade-4.0.3.5.2-4.0.3.5.3.sql','');

update apm_parameters set description = 'Order of first and last name when shown in conjunction. Default is &quot;1&quot; for FIRST_NAME LAST_NAME. If set to &quot;2&quot; name will be shown as LAST_NAME FIRST_NAME. If set to &quot;3&quot; name will be shown as LAST_NAME, FIRST_NAME' where description like 'Order of first and last name when shown in conjunction%';
