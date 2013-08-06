Ext.define('PO.model.Hour', {
    extend: 'Ext.data.Model',
    config: {
	fields: [
	    'id',					// Same as hour_id
	    'hour_id',					// Unique ID taken from im_hours_seq

	    'user_id',					// Who logged the hours?
	    'project_id',				// On which project or task?
	    'day',					// Which day (format: date, not timestamptz)

	    'hours',					// How many hours were logged?
	    'note',					// Comment for the logged hours
	    'internal_note',				// Comment hidden from customers (rarely used)

	    'cost_id',					// Link to cost item created to represent the internal cost of providing hours
	    'invoice_id',				// Invoice where hours have been billed to customer (optional)
	    'conf_object_id',				// Workflow "confirmation object" for timesheet approval (optional)
	    'material_id',				// Type of service provided during hours (rarely used)
	    'days',    					// Hours converted into days for daily invoicing (rarely used)

	    {   name: 'date',
                convert: function(value, record) {
                    return record.get('day').substring(0,10);
                }
            }


	],
	proxy: {
	    type:		'rest',
	    url:		'/intranet-rest/im_hour',
	    appendId:		true,			// Append the object_id: ../im_ticket/<object_id>
	    timeout:		300000,
	    
	    extraParams: {
		format:		'json'			// Tell the ]po[ REST to return JSON data.
	    },
	    reader: {
		type:		'json',			// Tell the Proxy Reader to parse JSON
		root:		'data',			// Where do the data start in the JSON file?
		totalProperty:  'total'			// Total number of tickets for pagination
	    },
	    writer: {
		type:		'json'			// Allow Sencha to write ticket changes
	    }
	}
    } 
});

