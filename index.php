<html>
<head>

<meta charset="utf-8" />

<meta name="robots" value="none" />

<title>F&#252;d</title> 
<link rel="stylesheet" type="text/css" href="style.css" />
<script src="http://maps.google.com/maps/api/js?sensor=false" type="text/javascript"></script>
<script type="text/javascript" src="js/jquery.js"></script> 
<script type="text/javascript" src="js/jquery.cookie.js"></script> 
<link href="js/jquery.mCustomScrollbar.css" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="js/jquery-ui.js"></script>
<script type="text/javascript" src="js/jquery.mousewheel.min.js"></script>
<script type="text/javascript" src="js/jquery.mCustomScrollbar.js"></script>
 <script type="text/javascript" src="http://www.google.com/jsapi?key=AIzaSyA4_MbXZb7jP5e9luRnPZRzZuvJOMyRuVM"></script>
<script type="text/javascript" src="js/decode.js"></script> 
<?php
if(isset($_GET['PHONEMODE'])){
?>
	<link rel="stylesheet" type="text/css" href="phone.css" />
<?php
}
?>
<script>

var selected = -1;

var funcarr = [];

function updateResizeDiv(){
	var mapwidther = $(window).width()-$('#comparebox').width();
	var mapheighter = ($(window).height()-$('#searchbox').height())-5;
	$('#introbox').css('width',mapwidther);
	$('#introbox').css('left',$('#comparebox').width());
	$('#introbox').css('height',mapheighter);
	$('#map').css('width',mapwidther);
	google.maps.event.trigger(map, 'resize');
	$('#map').css('left',$('#comparebox').width());
	$('#map').css('height',mapheighter);
	$('#introbox_inner').css('left',((mapwidther/2)-($('#introbox_inner').width()/2)));
	$('#introbox_inner').css('top',((mapheighter/2)-($('#introbox_inner').height()/2))-$('#searchbox').height());
	$('#introbox_inner_manual').css('left',((mapwidther/2)-($('#introbox_inner_manual').width()/2)));
	$('#introbox_inner_manual').css('top',((mapheighter/2)-($('#introbox_inner_manual').height()/2))-$('#searchbox').height());
	$('#comparebox').css('height',$(window).height()-$('#searchbox').height()-25);
}

function init_jsfud(){
	<?php
		if(!isset($_GET['q'])){
			echo '$("#introbox").fadeIn();';
		}
	?>
	updateResizeDiv();
	$("#comparebox").mCustomScrollbar();
	$('#introbox_inner').delay(800).fadeIn();
	$("#manual_searchdiv").click(function() {
		$("#introbox_inner_manual").fadeIn();
	});

	$("#intro_search_closebutton").click(function() {
		$('#introbox_inner').fadeOut();
	});

	$("#manual_search_closebutton").click(function() {
		$("#introbox_inner_manual").fadeOut();
	});
}

$(window).resize(updateResizeDiv);

</script>
<?php
include 'functions.php';
$srchjson=$_GET['q'];

$frompos = false;

if(!isset($_GET['q'])){
	$srchjson = false;
	$cursorlimit = 5;
}else{
	$srchjson = json_decode(stripslashes($srchjson));
	if(isset($srchjson->machine_location)){
		$frompos = reset($srchjson->machine_location);
	}
	$cursorlimit = 40;
}

$m = new Mongo('mongodb://heroku_app6583922:9o7p80dd1kabf1sc22huu9ot0m@ds037077-a.mongolab.com:37077/heroku_app6583922');
$db = $m->selectDB('heroku_app6583922');
$col = $db->selectCollection('places');

$cursor = $col->find(array(), array('_id' => 0))->limit($cursorlimit);

if(!isset($_GET['q'])){
	$cursor = $col->find(array(), array('_id' => 0))->limit($cursorlimit);
}else{
	$cursor = $col->find($srchjson, array('_id' => 0))->limit($cursorlimit);
}

for($i=1;$i < (($cursorlimit+1) > $cursor->count() ? $cursor->count() : ($cursorlimit+1));$i+=1){
	$comp_diff = true;
	$cur = $cursor->getNext();
	$place_items .= '[\'<div class="infobox" >';
	
	$comp_items .= '<div class="compbox" id="compbox_'.$i.'" >';
	
	add_script('
	
	$("#compbox_'.$i.'").click(function(){
		if(selected!=-1){
			$("#compbox_"+selected).attr("class", "compbox");
		}
		infowindow.setContent(stripslashes(locations['.($i-1).'][0]));
        infowindow.open(map, marker_array['.($i-1).']);
        $("#compbox_'.$i.'").attr("class", "compbox selected");
        selected = '.$i.';
	});
	
	');
	
	add_field(true,'name', '<strong>'.addslashes($cur['name']).'</strong> ');
	add_field(true,'rating', get_stars('<strong>Official Hygiene Rating: </strong>',intval($cur['rating_value']),'img/star_enabled.png','img/star_disabled.png'));
	if($cur['rating']){add_field(true,'googleplacesrating', get_stars('<strong>Google Places Rating: </strong> ('.$cur['rating'].') ', floor(intval($cur['rating'])),'img/star_enabled.png','img/star_disabled.png'));};
	add_field(true,'type','<strong>Type: </strong>'.$cur['business_type']);
	add_field(false,'website','<strong>Website: </strong><br/><a target="_blank" href="'.$cur['website'].'" >'.$cur['website'].'</a>');
	add_field(false,'number', '<strong>Phone Number: </strong><br/>'.$cur['formatted_phone_number']);
	add_field(false,'intnumber', '<strong>Int. Phone Number: </strong><br/>'.$cur['international_phone_number']);
	if(count($cur['allergies'])>0){
		add_field(true,'allergyinfo', '<strong>Allergy Information: </strong><br/>'.get_allergies($cur['allergies'],'img/warning_enabled.png','img/warning_disabled.png'));
	}
	add_field(false,'address','<strong>Address: </strong><br/>'.addslashes(str_replace(', ',',<br/>',$cur['formatted_address'])));
	if($frompos){
		add_field(false,'directions', '<strong>Directions: </strong><br/><div class="directionsdiv" id="directionsdiv_'.$i.'" >Loading directions...</div>');
		add_script('function loadDirectionsFor'.$i.'(){
			$.get("getdirections.php?olong='.$frompos['1'].'&olat='.$frompos['0'].'&nlong='.$cur['location']['longitude'].'&nlat='.$cur['location']['latitude'].'", function(data) {
				
				data = data.split("\n");
				$("#directionsdiv_'.($i+1).'").html(data[0]);

        var coords = [];

        for(var i=0; i < data.length-1; i++) {
          var a = decode(data[i]);
          for(var j=0; j < a.length; j++) {
            coords.push(a[j]);
          }
        }

        var points = [];

        for(var j = 0; j < coords.length; j++) {
          if(coords[j][0] < 200 && coords[j][1] < 200 && coords[j][0] > 40 && coords[j][1] > -200) {
            points.push(new google.maps.LatLng(coords[j][0], coords[j][1]));;
          }
        }

        var polyline = new google.maps.Polyline({
          path: points,
          strokeColor: "#FF0000",
          strokeOpacity: 1.0,
          strokeWeight: 2,
          map: map
        });

        polyline.setMap(map);
			});
		}
		funcarr['.$i.'] = loadDirectionsFor'.$i.';');
	}
	
	$comp_items .= '</div>';
	
	$place_items .= '</div>\', '.$cur['location']['longitude'].', '.$cur['location']['latitude'].', '.$i.']';
	if($i<$cursorlimit){
		$place_items .= ','."\n";
	}
}

$comp_items .= '<div id = "compbox_spacer" style = "height:5px;width:100%;"></div>';


?>

</head>

<body onload="init_jsfud();" >


<div id = "introbox" style="display:none;">
	<div id = "introbox_inner" style="position:relative;" class="intro_box">
		<img id="close_intro_button" ></img>
		
		<div style="width:100%; text-align:center;">
		<img src="img/fud_logo_large.png" /><br/>
			<font id = "ask_box" >where do you want to eat?</font><br/><br/>
				<div><form id="searchform_intro" method="post" action="http://infinite-island-5869.herokuapp.com/search" ><input id="searchbox_intro" type="text" name="query" placeholder="Enter a search query and press enter..." ></input><input type="submit" style="height:0px;width:0px;visibility:hidden;"></input></form><div id="manual_searchdiv" style="position:absolute;top:163px;left:58px" >+ manual search</div></div>
			<font id = "explanation_box" >e.g. "Indian Takeaway Near Me" or<br/>"Indian Takeaway Near Brighton Marina"<br/>("near me" tells Fud to automatically detect your location)</font>
			</div>
	</div>
	<div id = "introbox_inner_manual" style="display:none;position:absolute;" >
	</div>
</div>
	
	<div id = "comparebox" class="comparison_box">
		<?php
			echo $comp_items;
		?>
	</div>
	
	<div id="searchbox" class="search_box box">
		<img src="img/fud_logo.png" />
		<div id="search_div" style="
		<?php
		if(!isset($_GET['q'])){
			echo 'visibility:hidden;';
		}
		?>" ><form method="post" action="http://infinite-island-5869.herokuapp.com/search" ><input type="text" name="query" placeholder="Enter new search query and press enter..." ></input><input type="submit" style="visibility:hidden;"></input></form></div>
	</div>
  
<div id="map" style="position:absolute;left:330px;width:400px;height:100%;z-index:10;" ></div>

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
      center: new google.maps.LatLng(<?php
      if($frompos){
      	echo $frompos['1'].','.$frompos['0'];
      }else{
		echo '50.82253,-0.137163';
	  }
      ?>),
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      styles:[{
        featureType:"poi",
        stylers:[{
            visibility:"off"
        }]
      }]
    });
    
    var styles = [{
    stylers: [
      { hue: "#ff9100" },
      { lightness: 15 },
      { saturation: 88 },
      { gamma: 1.07 }
      ]
    }];
    
    var markericon_pizza = new google.maps.MarkerImage('img/marker_pizza-alt.png',
        new google.maps.Size(20, 40),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 40)
    );
	
	
	var markericon_me = new google.maps.MarkerImage('img/marker_me.png',
        new google.maps.Size(20, 40),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 40)
    );
	
    
    map.setOptions({styles: styles});
    
    
    var poly;
  	
  	var polyOptions = {
    	strokeColor: '#000000',
		strokeOpacity: 1.0,
    	strokeWeight: 3
	}
	poly = new google.maps.Polyline(polyOptions);
	poly.setMap(map);
	var path = poly.getPath();
    
    
    var marker_array = [];

    var infowindow = new google.maps.InfoWindow();

    var i, ibase;
    ibase=0;
    <?php
    if($frompos){
    ?>
    
    ibase = 1;
    marker_array[0] = new google.maps.Marker({
        position: new google.maps.LatLng(<?php echo $frompos['1'].','.$frompos['0']; ?>),
        map: map,
        icon: markericon_me
    });

    google.maps.event.addListener(marker_array[0], 'click', (function(marker, i) {
        return function() {
          infowindow.setContent('That\'s <a href = "http://www.youtube.com/watch?v=aEQcsuXnnnc" target="_blank" >you</a> that is,</br>that\'s your favourite <a href = "http://www.youtube.com/watch?v=IzdI_PecYx0" target="_blank" >food</a>.');
          infowindow.open(map, marker);
        }
    })(marker_array[0], i));
    
    <?php
    }
    ?>

    for (i = ibase; i < locations.length; i++) {  
      marker_array[i] = new google.maps.Marker({
        position: new google.maps.LatLng(locations[i][1], locations[i][2]),
        map: map,
        icon: markericon_pizza
      });

      google.maps.event.addListener(marker_array[i], 'click', (function(marker, i) {
        return function() {
          if(selected!=-1){
			$("#compbox_"+selected).attr("class", "compbox");
		  }
          infowindow.setContent(stripslashes(locations[i][0]));
          infowindow.open(map, marker);
          $("#compbox_"+i).attr("class", "compbox selected");
          $('#comparebox').animate({scrollTop:$("#compbox_"+i).position().top}, 'slow');
          selected = i;
          <?php if($frompos){ ?>
          	funcarr[i]();
          <?php } ?>
        }
      })(marker_array[i], i));
    }
  </script>

<script>
$(document).ready(function(){
	<?php
		echo $script_items;
	?>
});
</script>
</body>
</html>
