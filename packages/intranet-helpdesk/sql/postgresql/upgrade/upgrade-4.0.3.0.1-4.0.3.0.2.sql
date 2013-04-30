-- 
-- 
-- 
-- Copyright (c) 2013, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2013-03-09
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-helpdesk/sql/postgresql/upgrade/upgrade-4.0.3.0.1-4.0.3.0.2.sql','');
SELECT im_dynfield_widget__new (
       null,
       'im_dynfield_widget', 
       now(), 
       null,
       null, 
       null, 
       'ticket_status',
       'Ticket Status',
       'Ticket Status',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Status"}}',
       'im_name_from_id'
       );

SELECT im_dynfield_attribute_new (
	'im_ticket', 'ticket_status_id', 'Status', 'ticket_status', 'integer', 'f', 20, 't', 'im_tickets'
);

SELECT im_dynfield_widget__new (
       null,
      'im_dynfield_widget', 
       now(),
       null,
       null,
       null,
       'ticket_type',
       'Ticket Type',
       'Ticket Types',
       10007,
       'integer',
       'im_category_tree',
       'integer',
       '{custom {category_type "Intranet Ticket Type"}}',
       'im_name_from_id'
 );

SELECT im_dynfield_attribute_new (
	'im_ticket', 'ticket_type_id', '#intranet-helpdesk.Ticket_Type#', 'ticket_type', 'integer', 'f', 30, 't', 'im_tickets'
);

-- Ticket Info Component
SELECT im_component_plugin__new (
       null,
       'acs_object',
       now(),
       null,
       null,
       null,
       'Ticket Info Component',
       'intranet-helpdesk',
       'left', 
       '/intranet-helpdesk/view', 
       null,
       1,
       'im_ticket_info_component $ticket_id $return_url');

update im_component_plugins set page_url = '/intranet-helpdesk/view' where page_url = '/intranet-helpdesk/new';
update im_component_plugins set enabled_p = 'f' where plugin_name = 'Filestorage' and page_url = '/intranet-helpdesk/view';

