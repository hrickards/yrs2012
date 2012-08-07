<head>

<title>F&#252;d</title> 
<link rel="stylesheet" type="text/css" href="style.css" />
<script src="http://maps.google.com/maps/api/js?sensor=false" type="text/javascript"></script>

<?php
include 'functions.php';

$m = new Mongo('mongodb://178.79.184.102:27017');
$db = $m->selectDB('fud');
$col = $db->selectCollection('places');
$cursorlimit = 40;
$cursor = $col->find(array(), array('_id' => 0))->limit($cursorlimit);
?>

</head>

<body>


<div class="intro_box box">
		Intro Box
	</div>
	
	<div class="comparison_box box">
		
	</div>
	
	<div class="search_box box">
		<img src="img/fud_logo.png" />
	</div>
  
<div id="map" style="width:100%;height:100%;" ></div>

  <script type="text/javascript">
    var locations = [
		<?php
			for($i=1;$i<$cursorlimit+1;$i+=1){
				$cur = $cursor->getNext();
				echo '[\'<div class="infobox" ><div class="info_placename"> '.addslashes($cur['business_name']).'</div><hr/>';
				echo '<div class="info_placerating">'.get_stars('Hygiene Rating:',intval($cur['rating_value']),'img/star_enabled.gif','img/star_disabled.gif').'</div>';
				echo '</div>\', '.$cur['location']['latitude'].', '.$cur['location']['longitude'].', '.$i.']';
				if($i<$cursorlimit){
					echo ','."\n";
				}
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
    
    var styles = [{
    stylers: [
      { hue: "#ff9100" },
      { lightness: 15 },
      { saturation: 88 },
      { gamma: 1.07 }
      ]
    }];
    
    map.setOptions({styles: styles});

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