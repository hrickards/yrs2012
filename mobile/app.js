Ext.application({
    name: 'FUD',
    views: ['FUD.view.Map'],
    models: ['FUD.model.Place'],
    //stores: ['FUD.store.Places'],
    requires: [
      'Ext.Map',
      'Ext.tab.Panel'
    ],

    launch: function() {
      iterate over store here

      console.log(Ext.create('FUD.model.Place'));
      //console.log(Ext.create('FUD.store.Places'));
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
