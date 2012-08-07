<head>

<title>F&#252;d</title> 
<link rel="stylesheet" type="text/css" href="style.css" />
<script src="http://maps.google.com/maps/api/js?sensor=false" type="text/javascript"></script>

<?php
include 'functions.php';

$locarr = array(
	//    array(Place Name, Place Rating, Longitude, Lattitude)
	array(addslashes("Local Authority"), -1, 50.83483000000000, -0.20667300000000),
	array(addslashes("24 Convenience Store"), 5, 50.82409300000000, -0.13839100000000),
	array(addslashes("24 St George's Restaurant"), 3, 50.83483000000000, -0.20667300000000)
	
);

?>

</head>

<body>

<div id="map" style="width:100%;height:100%;" ></div>

  <script type="text/javascript">
    var locations = [
		<?php
			$i = 1;
			foreach($locarr as &$location){
				echo '[\'<div class="infobox" ><div class="info_placename"> '.$location[0].'</div><hr/>';
				if($location[1]!=-1){
					echo '<div class="info_placerating">'.get_stars('Hygiene Rating:',$location[1],'Images/star_enabled.gif','Images/star_disabled.gif').'</div>';
				}
				echo '</div>\', '.$location[2].', '.$location[3].', '.$i.']';
				if($i<count($locarr)){
					echo ',';
				}
				$i+=1;
			}
		?>
    ];
    
    //var Icon = new GIcon();
    //Icon.image = "mymarker.png";

    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 12,
      center: new google.maps.LatLng(50.83483000000000, -0.20667300000000),
      mapTypeId: google.maps.MapTypeId.ROADMAP
    });

    var infowindow = new google.maps.InfoWindow();

    var marker, i;

    for (i = 0; i < locations.length; i++) {  
      marker = new google.maps.Marker({
        position: new google.maps.LatLng(locations[i][1], locations[i][2]),
        map: map
      });

      google.maps.event.addListener(marker, 'click', (function(marker, i) {
        return function() {
          infowindow.setContent(locations[i][0]);
          infowindow.open(map, marker);
        }
      })(marker, i));
    }
  </script>

<body>