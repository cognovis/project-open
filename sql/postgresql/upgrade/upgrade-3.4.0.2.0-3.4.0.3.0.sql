-- upgrade-3.4.0.2.0-3.4.0.3.0.sql

-- Add a localized short status to absences
update lang_messages set message = 'Absent (%absence_status_3letter_l10n%):' where package_key = 'intranet-timesheet2' and message_key = 'Absent_1' and locale like 'en_%';

