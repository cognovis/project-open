        <script type="text/javascript">
                Ext.Loader.setConfig({enabled: true});
                Ext.Loader.setPath('Ext', '/intranet-sencha/');
                Ext.require([
                        'Ext.grid.*',
                        'Ext.tree.*',
                        'Ext.data.*',
                        'Ext.toolbar.*',
                        'Ext.tab.Panel',
                        'Ext.layout.container.Border'
                ]);
                Ext.onReady(function(){
                        Ext.QuickTips.init();
                        new TicketBrowser.Main();
                });
        </script>
