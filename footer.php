<script type="text/javascript">
/** This is high-level function.
 * It must react to delta being more/less than zero.
 */
function handle(delta) {
	var d=delta*-10;
	window.scrollBy(0,d);
	console.log("scrolling");
}

/** Event handler for mouse wheel event.
 */
function wheel(event){
        var delta = 0;
        if (!event) /* For IE. */
                event = window.event;
        if (event.wheelDelta) { /* IE/Opera. */
                delta = event.wheelDelta/120;
                /** In Opera 9, delta differs in sign as compared to IE.
                 */
                if (window.opera)
                        delta = -delta;
        } else if (event.detail) { /** Mozilla case. */
                /** In Mozilla, sign of delta is different than in IE.
                 * Also, delta is multiple of 3.
                 */
                delta = -event.detail/3;
        }
        /** If delta is nonzero, handle it.
         * Basically, delta is now positive if wheel was scrolled up,
         * and negative, if wheel was scrolled down.
         */
        if (delta)
                handle(delta);
        /** Prevent default actions caused by mouse wheel.
         * That might be ugly, but we handle scrolls somehow
         * anyway, so don't bother here..
         */
        if (event.preventDefault)
                event.preventDefault();
	event.returnValue = false;
}

/** Initialization code. 
 * If you use your own event management code, change it as required.
 */
if (window.addEventListener){
        document.getElementById('comparebox').addEventListener('DOMMouseScroll', wheel, false);
        //document.getElementById('comparebox').addEventListener("touchmove", wheel, false);
		//document.getElementById('comparebox').addEventListener("scroll", wheel, false);
}else{
	document.getElementById('comparebox').onmousewheel = wheel;
}

</script>