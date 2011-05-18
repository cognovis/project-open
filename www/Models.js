Ext.define('TicketBrowser.Sla', {
    extend: 'Ext.data.Model',
    idProperty: 'project_id',		// The primary key of object_id of the SLA project
    fields: [
	'project_id',			// The primary key of object_id of the SLA project
	'project_name',			// The name of the SLA
	{ name: 'leaf', convert: function(value, record) { return true; } }
    ]
});



// A "category" is a kind of constant frequently used for states and types
Ext.define('TicketBrowser.Category', {
    extend: 'Ext.data.Model',
    idProperty: 'category_id',		// The primary key of the category
    fields: [
        {type: 'int', name: 'category_id'},
        {type: 'string', name: 'tree_sortkey'},
        {type: 'string', name: 'category'},
        {type: 'string', name: 'category_translated'},
        {	name: 'pretty_name',
		convert: function(value, record) {
			var	category = record.get('category_translated'),
				indent = record.get('tree_sortkey').length - 8,
				result = '',
				i=0;
			for (i=0; i<indent; i++){
				result = result + '&nbsp;';
			}
			result = result + category;
			return result;
		}
        }
    ]
});



Ext.define('TicketBrowser.Ticket', {
    extend: 'Ext.data.Model',

    idProperty: 'ticket_id',		// The primary key or object_id of the ticket
    fields: [
	// Basic ticket fields with special meaning
	'ticket_id',			// The primary key or object_id of the ticket
	'project_name',			// The name of the ticket. Ticket is as sub-type of Project, 
					// so the ticket name is stored as project_name.
	'parent_id',			// The parent_id of the ticket is the Service Level Agreement (SLA)
					// project that handles the financials of the ticket.
	'creation_user',		// User_id of the guy creating the ticket
	'ticket_status_id',		// Lifecycle control: Current Status
	'ticket_type_id',		// Type of ticket: Controls presence/absence of DynFields
	'ticket_customer_contact_id',	// For whom do we work?

	// Main ticket fields
	'ticket_prio_id',		// Priority
	'ticket_assignee_id',		// Who is assigned to the work?
	'ticket_dept_id',		// Which department?
	'ticket_service_id',
	'ticket_hardware_id',
	'ticket_application_id',
	'ticket_queue_id',		// Assignee queue (currently not used)
	'ticket_conf_item_id',
	'ticket_component_id',
	'ticket_description',		// Initial description of the ticket
	'ticket_resolution_time',	// 
	'ticket_closed_in_1st_contact_p',

	// Alarm mechanism - not supported yet
	'ticket_alarm_date',
	'ticket_alarm_action',

	// Ticket lifecycle tracking	
	'ticket_creation_date',		// 
	'ticket_reaction_date',		// 
	'ticket_confirmation_date',		// 
	'ticket_done_date',		// 
	'ticket_signoff_date',		// 

	'replycount'			// Number of ticket replies - not supported at the moment
    ]
});


