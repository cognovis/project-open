Ext.define('ForumBrowser.Forum', {
    extend: 'Ext.data.Model',
    fields: ['id', 'text']
});

Ext.define('ForumBrowser.Topic', {
    extend: 'Ext.data.Model',
    idProperty: 'threadid',
    fields: ['title', 'forumtitle', 'forumid', 'author', 'lastpost',
    {   name: 'replycount', type: 'int' }, 
    'lastposter', 'excerpt']
});