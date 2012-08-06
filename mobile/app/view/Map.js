Ext.define('FUD.view.Map', {
  extend: 'Ext.Map',

  config: {
    mapOptions: {
      center : new google.maps.LatLng(37.381592, -122.135672),
      zoom : 12,
      mapTypeId : google.maps.MapTypeId.ROADMAP,
      navigationControl: true,
      navigationControlOptions: {
        style: google.maps.NavigationControlStyle.DEFAULT
      }
    }
  }
});
