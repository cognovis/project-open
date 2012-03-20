Ext.define('ProjectOpen.controller.Speakers', {
	extend: 'Ext.app.Controller',
	config: {
		refs: {
			speakerContainer: 'speakerContainer',
			speakers: 'speakerContainer speakers',
			speaker: 'speakerContainer speaker',
			speakerInfo: 'speakerContainer speakerInfo',
			projects: 'speakerContainer speaker list'
		},
		control: {
			speakers: {
				itemtap: 'onSpeakerTap',
				activate: 'onSpeakersActivate'
			},
			projects: {
				itemtap: 'onProjectTap'
			}
		}
	},

	onSpeakerTap: function(list, idx, el, record) {

		var projectStore = Ext.getStore('SpeakerProjects'),
			projectIds = record.get('projectIds');

		projectStore.clearFilter();
		projectStore.filterBy(function(project) {
			return Ext.Array.contains(projectIds, project.get('id'));
		});

		if (!this.speaker) {
			this.speaker = Ext.widget('speaker');
		}

		this.speaker.config.title = record.getFullName();
		this.getSpeakerContainer().push(this.speaker);
		this.getSpeakerInfo().setRecord(record);
	},

	onProjectTap: function(list, idx, el, record) {

		if (!this.projectInfo) {
			this.projectInfo = Ext.widget('projectInfo');
		}

		this.projectInfo.config.title = record.get('title');
		this.projectInfo.setRecord(record);
		this.getSpeakerContainer().push(this.projectInfo);
	},

	onSpeakersActivate: function() {
		if (this.speaker) {
			this.speaker.down('list').deselectAll();
		}
	}

});
