<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<link rel='stylesheet' href='/intranet-sencha/css/example.css' type='text/css' media='screen'>
	<script type="text/javascript" src="/intranet-sencha/js/bootstrap.js"></script> 
	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>
</head> 
<body id="docbody"> 
<h1>Drop-Down</h1> 


<form method=GET>
<div id="simpleCombo"></div> 
<input type=submit>
</form>


<script type="text/javascript">

Ext.require([
    'Ext.form.field.*',
    'Ext.form.*',
    'Ext.tip.*',
    'Ext.data.*'
]);

// A category basically consists of an ID and a string.
Ext.define('TicketBrowser.Category', {
    extend: 'Ext.data.Model',
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

var store = Ext.create('Ext.data.Store', {
	autoLoad: true,
	model: 'TicketBrowser.Category',
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json',
			query: 'category_type=\'Intranet Ticket Type\''
		},
		reader: {
			type: 'json',
			root: 'data'
		}
	}
});

// Sort by ...
store.sort('tree_sortkey');

// Simple ComboBox using the data store
var simpleCombo = Ext.create('Ext.form.field.ComboBox', {
    fieldLabel: 'Select a single state',
    renderTo: 'simpleCombo',
    displayField: 'pretty_name',
    valueField: 'category_id',
    width: 500,
    labelWidth: 130,
    store: store,
    queryMode: 'local',
    typeAhead: true
});


</script>
</body>
</html>

