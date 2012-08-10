
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
$comp_diff = true;

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

function add_field($compare,$namer,$html){
	global $comp_items,$place_items,$comp_diff;
	$place_items .= '<div class="info_place'.$namer.' placeinfobox">'.addslashes($html).'</div><br/>';
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


?>