Ext.define('PO.view.BlogList', {
	extend: 'Ext.NestedList',
	xtype: 'blogList',

	config: {
		title: 'Blog',
		iconCls: 'star',

		    displayField: 'title',

		    detailCard: {
			xtype: 'panel',
			scrollable: true,
			styleHtmlContent: true
		    },

		    listeners: {
		    	itemtap: function(nestedList, list, index, element, post) {
				 this.getDetailCard().setHtml(post.get('content'));
		    	}
		    },

		    store: {
			type: 'tree',
			fields: [
			    'title', 'link', 'author', 'contentSnippet', 'content',
			    {name: 'leaf', defaultValue: true}
			],
			root: {
			    leaf: false
			},
			proxy: {
			    type: 'jsonp',
			    url: 'https://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=http://feeds.feedburner.com/SenchaBlog',
			    reader: {
				type: 'json',
				rootProperty: 'responseData.feed.entries'
			    }
			}
		    }
	}

    });



