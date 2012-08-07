<?php

function get_stars($trailer,$count,$starurl,$emptyurl){
	echo '<div class="starbox" >';
	echo '<div class="starbox_trailer" style="float:left;" >'.$trailer.'</div>';
	for($i=0; $i<$count; $i+=1){
		echo '<img class="stars_enabled" src="'.$starurl.'" style="float:left;" />';
	}
	for($i=0; $i<(5-$count); $i+=1){
		echo '<img class="stars_disabled" src="'.$emptyurl.'" style="float:left;" />';
	}
	echo '</div>';
}

?>