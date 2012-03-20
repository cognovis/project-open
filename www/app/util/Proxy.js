Ext.define('ProjectOpen.util.Proxy', {
	singleton: true,
	process: function(url, callback) {

		var projectStore = Ext.getStore('Projects'),
		    speakerStore = Ext.getStore('Speakers'),
		    projectSpeakerStore = Ext.getStore('ProjectSpeakers'),
		    speakerProjectStore = Ext.getStore('SpeakerProjects'),
		    projectIds, proposalModel, speakerModel, speakerProjects = {}, projectId, speaker, projectDays = {};

		Ext.data.JsonP.request({
		    url: url,
		    callbackName: 'feedCb',

		    success: function(data) {

		        Ext.Array.each(data.proposals, function(proposal) {

		            proposal.speakerIds = [];
		            proposalModel = Ext.create('ProjectOpen.model.Project', proposal);

		            Ext.Array.each(proposal.speakers, function(speaker) {
		                proposal.speakerIds.push(speaker.id);

		                speakerModel = Ext.create('ProjectOpen.model.Speaker', speaker);
		                speakerStore.add(speakerModel);
		                projectSpeakerStore.add(speakerModel);

		                speakerProjects[speaker.id] = speakerProjects[speaker.id] || [];
		                speakerProjects[speaker.id].push(proposal.id);
		            });

		            if (proposal.date) {
		                projectDays[proposal.date] = {
		                    day: proposalModel.get('time').getDate(),
		                    text: Ext.Date.format(proposalModel.get('time'), 'm/d'),
		                    time: proposalModel.get('time')
		                };
		            }

		            projectStore.add(proposalModel);
		            speakerProjectStore.add(proposalModel);
		        });

		        for (speakerId in speakerProjects) {
		            speaker = speakerStore.findRecord('id', speakerId);
		            if (speaker) {
		                speaker.set('projectIds', speakerProjects[speakerId]);
		            }
		        }

		        ProjectOpen.projectDays = Ext.Array.sort(Ext.Object.getValues(projectDays), function(a, b) {
		            return a.time < b.time ? -1 : 1;
		        });

		        callback();
		    }
		});
	}
});
