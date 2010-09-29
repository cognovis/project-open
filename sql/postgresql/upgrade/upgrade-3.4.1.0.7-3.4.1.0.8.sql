-- upgrade-3.4.1.0.6-3.4.1.0.8.sql

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-3.4.1.0.6-3.4.1.0.8.sql','');


SELECT im_category_new(30540, 'Associate', 'Intranet Ticket Action');


update im_biz_object_urls 
set url = '/intranet-helpdesk/new?form_mode=display&ticket_id='
where object_type = 'im_ticket' and url_type = 'view';

