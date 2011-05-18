Ext.define('TicketBrowser.Sla', {
    extend: 'Ext.data.Model',
    idProperty: 'project_id',		// The primary key of object_id of the SLA project
    fields: [
	'project_id',			// The primary key of object_id of the SLA project
	'project_name'			// The name of the SLA
    ]
});

Ext.define('TicketBrowser.Ticket', {
    extend: 'Ext.data.Model',
    idProperty: 'ticket_id',		// The primary key or object_id of the ticket
    fields: [
	'ticket_id',			// The primary key or object_id of the ticket
	'project_name',			// The name of the ticket. Ticket is as sub-type of Project, 
					// so the ticket name is stored as project_name.
	'ticket_sla_id',		// Every ticket is associated with a Service Level Agreement (SLA)
					// project that handles the financials of the ticket.
	'creation_user',		// User_id of the guy creating the ticket
	'creation_date',		// Creation date of the ticket
	'replycount',			// Number of ticket replies
	'ticket_description'		// Initial description of the ticket
    ]
});

