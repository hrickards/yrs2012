Ext.define('FUD.model.Place', {
  etend: 'Ext.data.Model',
  config: {
    fields: ['name', 'latitude', 'longitude'],
    proxy: {
      type: 'rest',
      url: 'data/places',
      reader: {
        type: 'json',
        root: 'places'
      }
    }
  }
});
