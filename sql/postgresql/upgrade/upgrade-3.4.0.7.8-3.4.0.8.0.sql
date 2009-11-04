-- upgrade-3.4.0.7.8-3.4.0.8.0.sql

SELECT acs_log__debug('/packages/intranet-workflow/sql/postgresql/upgrade/upgrade-3.4.0.7.8-3.4.0.8.0.sql','');

\i ../workflow-expense_approval_wf-create.sql
\i ../workflow-feature_request_wf-create.sql
\i ../workflow-project_approval_wf-create.sql
\i ../workflow-rfc_approval_wf-create.sql
\i ../workflow-ticket_generic_wf-create.sql
\i ../workflow-ticket_workflow_generic_wf-create.sql
\i ../workflow-timesheet_approval_wf-create.sql
\i ../workflow-vacation_approval_wf-create.sql

