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
Ext.regModel('Category', {
    fields: [
        {type: 'int', name: 'id', useNull: true},
        {type: 'string', name: 'category'}
    ]
});

var store = Ext.create('Ext.data.Store', {
	autoLoad: true,
	model: 'Category',
	proxy: {
		type: 'rest',
		url: '/intranet-rest/im_category',
		appendId: true,
		extraParams: {
			format: 'json', 
			format_variant: 'sencha',
			query: 'category_type = \'Intranet Project Type\''
		},
		reader: {
			type: 'json',
			root: 'data'
		}
	}
});

// Sort by ...
store.sort('category');

// Simple ComboBox using the data store
var simpleCombo = Ext.create('Ext.form.field.ComboBox', {
    fieldLabel: 'Select a single state',
    renderTo: 'simpleCombo',
    displayField: 'category',
    valueField: 'id',
    width: 500,
    labelWidth: 130,
    store: store,
    queryMode: 'local',
    typeAhead: true
});


</script>
</body>
</html>

