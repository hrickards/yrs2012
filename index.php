<head>

<title>F&#252;d</title> 
<link rel="stylesheet" type="text/css" href="style.css" />
<script src="http://maps.google.com/maps/api/js?sensor=false" type="text/javascript"></script>

<?php
include 'functions.php';

$m = new Mongo('mongodb://178.79.184.102:27017');
$db = $m->selectDB('fud');
$col = $db->selectCollection('places');
$cursorlimit = 8;
$cursor = $col->find(array(), array('_id' => 0))->limit($cursorlimit);

for($i=1;$i<$cursorlimit+1;$i+=1){
	$comp_diff = true;
	$cur = $cursor->getNext();
	$place_items .= '[\'<div class="infobox" >';
	
	$comp_items .= '<div class="compbox" >';
	
	add_field(true,'name', '<strong>'.addslashes($cur['name']).'</strong><hr/>');
	add_field(true,'rating', get_stars('<strong>Official Hygiene Rating: </strong>',intval($cur['rating_value']),'img/star_enabled.png','img/star_disabled.png'));
	add_field(true,'googleplacesrating', '<strong>Google Places Rating: </strong>'.$cur['rating']);
	add_field(true,'type','<strong>Type: </strong> '.$cur['business_type']);
	add_field(false,'website','<strong>Website: </strong> '.$cur['website']);
	add_field(false,'number', '<strong>Phone Number: </strong>'.$cur['formatted_phone_number']);
	add_field(false,'intnumber', '<strong>Int. Phone Number: </strong>'.$cur['international_phone_number']);
	add_field(true,'allergyinfo', '<strong>Allergy Information: </strong><br/>(no problem -> problematic)<br/>'.get_allergies($cur['allergies'],'img/allergy_enabled.png','img/allergy_disabled.png'));
	add_field(false,'address','<strong>Address: </strong><br/>'.addslashes($cur['address_line1']).'<br/>'.addslashes($cur['address_line2']).'<br/>'.addslashes($cur['address_line3']).'<br/>'.addslashes($cur['address_line4']));
	
	$comp_items .= '</div>';
	
	$place_items .= '</div>\', '.$cur['location']['latitude'].', '.$cur['location']['longitude'].', '.$i.']';
	if($i<$cursorlimit){
		$place_items .= ','."\n";
	}
}

$comp_items .= '<div id = "compbox_spacer" style = "height:40px;width:100%;"></div>';


?>

</head>

<body>


<div class="intro_box box">
		Intro Box
	</div>
	
	<div id = "comparebox" class="comparison_box box">
		<?php
			echo $comp_items;
		?>
	</div>
	
	<div class="search_box box">
		<img src="img/fud_logo.png" />
	</div>
  
<div id="map" style="width:100%;height:100%;" ></div>

  <script type="text/javascript">
    var locations = [
		<?php
			echo $place_items;
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