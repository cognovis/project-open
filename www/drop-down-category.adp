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

<div id="simpleCombo"></div> 

<script type="text/javascript">

Ext.require([
    'Ext.form.field.*',
    'Ext.form.*',
    'Ext.tip.*',
    'Ext.data.*'
]);


// Define the model for a State
Ext.regModel('State', {
    fields: [
        {type: 'string', name: 'abbr'},
        {type: 'string', name: 'name'},
        {type: 'string', name: 'slogan'}
    ]
});

// The data for all states
var states = [
        {"abbr":"AL","name":"Alabama","slogan":"The Heart of Dixie"},
        {"abbr":"AK","name":"Alaska","slogan":"The Land of the Midnight Sun"},
        {"abbr":"AZ","name":"Arizona","slogan":"The Grand Canyon State"},
        {"abbr":"WY","name":"Wyoming","slogan":"Like No Place on Earth"}
];

// The data store holding the states
var store = Ext.create('Ext.data.Store', {
    model: 'State',
    data: states
});

// Simple ComboBox using the data store
var simpleCombo = Ext.create('Ext.form.field.ComboBox', {
    fieldLabel: 'Select a single state',
    renderTo: 'simpleCombo',
    displayField: 'name',
    width: 500,
    labelWidth: 130,
    store: store,
    queryMode: 'local',
    typeAhead: true
});




</script>
</body>
</html>

