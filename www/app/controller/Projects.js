Ext.define('ProjectOpen.controller.Projects', {
	extend: 'Ext.app.Controller',
	config: {
		refs: {
			projects: 'projects',
			project: 'project',
			projectInfo: 'projectContainer projectInfo',
			projectSpeakers: 'projectContainer list',
			projectContainer: 'projectContainer',
			projectDatePicker: 'projects datepickerfield',
			speakers: 'projectContainer speakers',
			speakerInfo: 'projectContainer speakerInfo'
		},
		control: {
			projects: {
				initialize: 'initProjects',
				itemtap: 'onProjectTap',
				activate: 'onProjectsActivate'
			},
			projectDatePicker: {
				change: 'onProjectDateChange'
			},
			speakers: {
				itemtap: 'onSpeakerTap'
			}
		}
	},

	initProjects: function() {
		var firstButton = this.getProjectDatePicker();
		this.filterByDate(firstButton);
	},

	onProjectDateChange: function(seg, btn) {
		this.filterByDate(btn);
	},

	filterByDate: function(btnDate) {
		// Reload the projects of the project store
		var projectStore = Ext.getStore('Projects');
		projectStore.removeAll();
		projectStore.load();

		if (this.getProjectSpeakers()) {
			this.getProjectSpeakers().deselectAll();
		}
		Ext.getStore('Projects').clearFilter(true);
		Ext.getStore('Projects').filter(function(record) {
			var startDate = Date.parse(record.get('start_date'));
			var endDate = Date.parse(record.get('end_date'));
			var curDate = Date.parse(btnDate.toString());
			return true;
		});
	},

	onProjectTap: function(list, idx, el, record) {
		var speakerStore = Ext.getStore('ProjectSpeakers'),
		    speakerIds = record.get('speakerIds');
		speakerStore.clearFilter();
		speakerStore.filterBy(function(speaker) {
			return Ext.Array.contains(speakerIds, speaker.get('id'));
		});
		if (!this.project) {
			this.project = Ext.widget('project');
		}
		this.project.config.title = record.get('title');
		this.getProjectContainer().push(this.project);
		this.getProjectInfo().setRecord(record);
	},

	onSpeakerTap: function(list, idx, el, record) {
		if (!this.speakerInfo) {
			this.speakerInfo = Ext.widget('speakerInfo', {
				scrollable: 'vertical'
			});
		}
		this.speakerInfo.config.title = record.getFullName();
		this.speakerInfo.setRecord(record);
		this.getProjectContainer().push(this.speakerInfo);
	},

	onProjectsActivate: function() {
		if (this.project) {
			this.project.down('speakers').deselectAll();
		}
	}
});
