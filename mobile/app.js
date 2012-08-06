Ext.application({
    name: 'FUD',
    views: ['Map'],
    requires: [
      'Ext.Map',
      'Ext.tab.Panel'
    ],

    launch: function() {
      var map = Ext.create('FUD.view.Map');

      Ext.create('Ext.tab.Panel', {
        fullscreen: true,
        tabBarPosition: 'bottom',

        items: [
          {
            title: 'Map',
            iconCls: 'maps',
            layout: 'fit',
            items: [map]
          },
          {
            title: 'Search',
            iconCls: 'search',

            html: 'bar'
          }
        ]
      });
    }
});
