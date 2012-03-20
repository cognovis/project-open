//<debug>
Ext.Loader.setPath({
    'Ext': '../../src',
    'ProjectOpen': 'app'
});
//</debug>

Ext.require('ProjectOpen.util.Proxy');

Ext.application({
    // Change the values below to re-configure the app for a different conference.

    title:   'Web 2.0 Summit 2010',
    dataUrl: 'http://en.oreilly.com/web2010/public/mobile_app/all',

    twitterSearch: '#projop',

    mapCenter: [37.788539, -122.401643],
    mapText: 'The Palace Hotel<br /><small>2 New Montgomery Street<br />San Francisco, CA 94105<br />(415) 512-1111</small>',

    aboutPages: [
        {
            title: 'Overview',
            xtype: 'htmlPage',
            url: 'data/about.html'
        },
        {
            title: 'Sponsors',
            xtype: 'htmlPage',
            url: 'data/sponsors.html'
        },
        {
            title: 'Credits',
            xtype: 'htmlPage',
            url: 'data/credits.html'
        },
        {
            title: 'Videos',
            xtype: 'videoList',
            playlistId: '2737D508F656CCF8',
            hideText: 'Web 2.0 Summit 2010: '
        }
    ],

    // App namespace

    name: 'ProjectOpen',
    phoneStartupScreen:  'resources/img/startup.png',
    tabletStartupScreen: 'resources/img/startup_640.png',
    glossOnIcon: false,
    icon: {
        57: 'resources/img/icon.png',
        72: 'resources/img/icon-72.png',
        114: 'resources/img/icon-114.png'
    },

    // Dependencies
    requires: ['ProjectOpen.util.Proxy'],

    models: [
        'Project',
        'Speaker'
    ],

    views: [
        'Main',

        'project.Card',
        'project.List',
        'project.Detail',
        'project.Info',

        'speaker.Card',
        'speaker.List',
        'speaker.Detail',
        'speaker.Info',

        'Tweets',

        'about.Card',
        'about.List',
        'about.HtmlPage',
        'about.VideoList'
    ],

    controllers: [
        'Projects',
        'Speakers',
        'Tweets',
        'About'
    ],

    stores: [
        'Projects',
        'SpeakerProjects',
        'Speakers',
        'ProjectSpeakers',
        'Tweets',
        'Videos'
    ],

    viewport: {
        autoMaximize: true
    },

    // This is where the app starts
    launch: function() {

	// Mask out the main screen with the "loading" GIF        	    
        Ext.Viewport.setMasked({ xtype: 'loadmask' });

	// Load the "feed.js", "activate" the app and remove the loading GIF.
	// From now on the "main" panel handles events.
	/*
	ProjectOpen.util.Proxy.process('data/feed.js', function() {
            Ext.Viewport.add({ xtype: 'main' });
            Ext.Viewport.setMasked(false);
        });
	*/
	var projectStore = Ext.getStore('Projects');
	projectStore.load(function() {
            Ext.Viewport.add({ xtype: 'main' });
            Ext.Viewport.setMasked(false);
        });
    }
});
