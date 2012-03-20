Ext.define('ProjectOpen.model.Speaker', {
	extend: 'Ext.data.Model',
	config: {
		fields: [
			'id',
			'first_name',
			'last_name',
			'projectIds',
			'bio',
			'position',
			'photo',
			'affiliation',
			'url',
			'twitter'
		]
	},
	getFullName: function() {
		return this.get('first_name') + ' ' + this.get('last_name');
	}
});

