<?php
$comp_items="";
$place_items="";

function get_stars($trailer,$count,$starurl,$emptyurl){
	$output = "";
	$output .= '<div class="starbox" >';
	$output .= '<div class="starbox_trailer" style="float:left;" >'.$trailer.'</div>';
	for($i=0; $i<$count; $i+=1){
		$output .= '<img class="stars_enabled" src="'.$starurl.'" style="float:left;" />';
	}
	for($i=0; $i<(5-$count); $i+=1){
		$output .= '<img class="stars_disabled" src="'.$emptyurl.'" style="float:left;" />';
	}
	$output .= '</div>';
	return $output;
}


function add_field($compare,$namer,$html){
	global $comp_items,$place_items;
	$place_items .= '<div class="info_place'.$namer.'">'.$html.'</div><br/>';
	if($compare){
		$comp_items .= '<div class="comp_place'.$namer.'">'.$html.'</div>';
	}
}



?>