//<debug>
Ext.Loader.setPath({
    'Ext': '../../src',
    'ProjectOpen': 'app'
});
//</debug>

Ext.require('ProjectOpen.util.Proxy');

Ext.application({
    // Change the values below to re-configure the app for a different conference.

    title:   ']project-open[ Timesheet',
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
        'Session',
        'Speaker',
	'Project'
    ],

    views: [
        'Main',

        'session.Card',
        'session.List',
        'session.Detail',
        'session.Info',

        'project.Card',
        'project.List',
        'project.Detail',
        'project.Info',

        'speaker.Card',
        'speaker.List',
        'speaker.Detail',
        'speaker.Info',

        'Tweets',
        'Location',

        'about.Card',
        'about.List',
        'about.HtmlPage',
        'about.VideoList'
    ],

    controllers: [
        'Sessions',
	'Projects',
        'Speakers',
        'Tweets',
        'About'
    ],

    stores: [
        'Sessions',
	'Projects',
	'ProjectSpeakers',
	'SpeakerProjects',
        'SpeakerSessions',
        'Speakers',
        'SessionSpeakers',
        'Tweets',
        'Videos'
    ],

    viewport: {
        autoMaximize: true
    },

    launch: function() {

        Ext.Viewport.setMasked({ xtype: 'loadmask' });

	var projectStore = Ext.getStore('Projects');

        ProjectOpen.util.Proxy.process('data/feed.js', function() {
            Ext.Viewport.add({ xtype: 'main' });
            Ext.Viewport.setMasked(false);
        });

        // setInterval(function(){
        //     Ext.DomQuery.select('link')[0].href = "resources/css/oreilly.css?" + Math.ceil(Math.random() * 100000000)
        // }, 1000);
    }

});
