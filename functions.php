
<script type="text/javascript">

function stripslashes(str) {
	str=str.replace(/\\'/g,'\'');
	str=str.replace(/\\"/g,'"');
	str=str.replace(/\\0/g,'\0');
	str=str.replace(/\\\\/g,'\\');
	return str;
}

</script>


<?php
$comp_items="";
$place_items="";
$script_items="";
$comp_diff = true;

$tabs = array('<div class="tab1 tab">','<div style="display:none;" class="tab2 tab">','<div style="display:none;" class="tab3 tab">');

function get_stars($trailer,$count,$starurl,$emptyurl){
	$output = "";
	$output .= '<div class="starbox" >';
	$output .= '<div class="starbox_trailer" style="float:left;" >'.$trailer.'</div>';
	$output .= '<div class="starbox_stars" >';
	for($i=0; $i<$count; $i+=1){
		$output .= '<img class="stars_enabled" src="'.$starurl.'" style="float:left;" />';
	}
	for($i=0; $i<(5-$count); $i+=1){
		$output .= '<img class="stars_disabled" src="'.$emptyurl.'" style="float:left;" />';
	}
	$output .= '</div></div>';
	return $output;
}

function add_script($script){
	global $script_items;
	$script_items .= $script;
}

function get_allergies($allarr,$starurl,$emptyurl){
	$output = "";
	$first = true;
	foreach($allarr as &$allergy){
		if(key($allarr)!=''){
			$output .= '<div class = "allergy_item" ';
			if($first){
				$output .= 'style="margin-top:5px;"';
			}
			$output .= ' >'.get_stars(str_replace("_"," ",key($allarr)).':',$allergy,$starurl,$emptyurl).'</div>';
		}
		next($allarr);
		$first = false;
	}
	return $output;
}

function add_field($tabno,$compare,$namer,$html){
	global $comp_items,$place_items,$comp_diff;
	if($tabno==-1){
		$place_items .= '<div class="info_place'.$namer.' placeinfobox">'.addslashes($html).'</div><br/>';
	}else{
		$tabs[$tabno] .= '<div class="info_place'.$namer.' placeinfobox">'.addslashes($html).'</div><br/>';
	}
	if($compare){
		$comp_items .= '<div class="comp_place'.$namer.' compinfobox ';
		if($comp_diff){
			$comp_items .= 'compdiff1';
			$comp_diff = false;
		}else{
			$comp_items .= 'compdiff2';
			$comp_diff = true;
		}
		$comp_items .= '">'.stripslashes($html).'</div>';
	}
}

function get_directions($type,$fromlong,$fromlat,$tolong,$tolat){
	$direct = file_get_contents('http://maps.googleapis.com/maps/api/directions/'.$type.'?origin='.$fromlong.','.$fromlat.'&destination='.$tolong.','.$tolat.'&sensor=false');
	$direct = json_decode(stripslashes($direct));
	$direct = $direct->routes['legs']['steps'];
	$output = '<div class="directions_box">';
	foreach($direct as &$direction){
		$output .= $direction["html_instructions"].'<br/>';
	}
	$output .= '</div>';
	return $output;
}


?>