/**
 * This simple example shows the ability of the Ext.List component.
 *
 * In this example, it uses a grouped store to show group headers in the list. It also
 * includes an indicator so you can quickly swipe through each of the groups. On top of that
 * it has a disclosure button so you can disclose more information for a list item.
 */

//define the application
Ext.application({
    //define the startupscreens for tablet and phone, as well as the icon
    phoneStartupScreen: '/intranet-sencha/touch/examples/list/resources/loading/Homescreen.jpg',
    tabletStartupScreen: '/intranet-sencha/touch/examples/list/resources/loading/Homescreen~ipad.jpg',

    glossOnIcon: false,
    icon: {
        57: '/intranet-sencha/touch/examples/list/resources/icons/icon.png',
        72: '/intranet-sencha/touch/examples/list/resources/icons/icon@72.png',
        114: '/intranet-sencha/touch/examples/list/resources/icons/icon@2x.png',
        144: '/intranet-sencha/touch/examples/list/resources/icons/icon@114.png'
    },

    //require any components/classes what we will use in our example
    requires: [
        'Ext.data.Store',
        'Ext.List',
        'Ext.plugin.PullRefresh'
    ],

    /**
     * The launch method is called when the browser is ready, and the application can launch.
     *
     * Inside our launch method we create the list and show in in the viewport. We get the lists configuration
     * using the getListConfiguration method which we defined below.
     *
     * If the user is not on a phone, we wrap the list inside a panel which is centered on the page.
     */
    launch: function() {
        //get the configuration for the list
        var listConfiguration = this.getListConfiguration();

        //if the device is not a phone, we want to create a centered panel and put the list
        //into that
        if (!Ext.os.is.Phone) {
            //use Ext.Viewport.add to add a new component into the viewport
            Ext.Viewport.add({
                //give it an xtype of panel
                xtype: 'panel',

                //give it a fixed witdh and height
                width: 350,
                height: 370,

                //make it centered
                centered: true,

                //make the component modal so there is a mask around the panel
                modal: true,

                //set hideOnMaskTap to false so the panel does not hide when you tap on the mask
                hideOnMaskTap: false,

                //give it a layout of fit so the list stretches to the size of this panel
                layout: 'fit',

                //insert the listConfiguration as an item into this panel
                items: [listConfiguration]
            });
        } else {
            //if we are a phone, simply add the list as an item to the viewport
            Ext.Viewport.add(listConfiguration);
        }
    },

    /**
     * Returns a configuration object to be used when adding the list to the viewport.
     */
    getListConfiguration: function() {

	var userStore = Ext.create('Ext.data.Store', {
	fields: [
		'user_id',				// primary key
		'first_names',				// first name(s)
		'last_name',				// standard last name
		'email'					// email (should be lower case)
	],

	    proxy: {
	        type:			'rest',
	        url:			'/intranet-rest/user',
		appendId:		true,			// append the user_id to the URL
		extraParams: {
			format:		'json',			// tell the REST interface it should output JSON format
			format_variant: 'sencha'		// not necessary anymore(?)
		},
		reader: {
			type:		'json',			// the Sencha to parse JSON data
			rootProperty:	'data',			// the JSON root
			totalProperty:	'total',		// lists contain the size of the list in the "total" field
			messageProperty:'message'
		}
	    },
	    autoLoad:			true,
	
	    //filter the data using the first_names field
	    sorters: 'first_names'
	
	});

        return {
            //give it an xtype of list for the list component
            xtype: 'list',

            //set the itemtpl to show the fields for the store
            itemTpl: '<div class="contact2"><strong>{first_names}</strong> {last_name}</div>',

            //enable disclosure icons
            disclosure: true,

            //enable the indexBar
            indexBar: true,

            //set the function when a user taps on a disclsoure icon
            onItemDisclosure: function(record, item, index, e) {
                //show a messagebox alert which shows the persons first_names
                e.stopEvent();
                Ext.Msg.alert('Disclose', 'Disclose more info for ' + record.get('first_names'));
            },

            //bind the store to this list
            store: userStore
        };
    }
});
