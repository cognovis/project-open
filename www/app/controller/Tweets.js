Ext.define('ProjectOpen.controller.Tweets', {
	extend: 'Ext.app.Controller',

	config: {
		refs: {
			title: 'tweets titlebar'
		},
		control: {
			tweets: {
				activate: 'onActivate'
			}
		}
	},

	onActivate: function() {
		if (!this.loadedTweets) {

			this.getTitle().setTitle(ProjectOpen.app.twitterSearch);

			Ext.getStore('Tweets').getProxy().setExtraParams({
				q: ProjectOpen.app.twitterSearch
			});
			Ext.getStore('Tweets').load();

			this.loadedTweets = true;
		}
	}

});
