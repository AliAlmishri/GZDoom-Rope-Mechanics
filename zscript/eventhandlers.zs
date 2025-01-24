class GrappleHandler : EventHandler {
	override void NetworkProcess(ConsoleEvent e) {
		if(e.name == "grapple"){
			let GSPlayer = GrapplePlayer((Players[consoleplayer].mo)); 
			if (GSPlayer){
				GSPlayer.FireGrapple();
			}
			
		}
		if(e.name == "swingforward"){
			let GSPlayer = GrapplePlayer(Players[consoleplayer].mo);
			if(GSPlayer){
				GSPlayer.toggleForwardSwing();
			}
		}	
		if(e.name == "swingbackward"){
			let GSPlayer = GrapplePlayer(Players[consoleplayer].mo);
			if(GSPlayer){
				GSPlayer.toggleForwardSwing();
			}
		}
		if(e.name == "drawplane"){ // i dont think i even use this?
			//gzdoom hates sending network events so do this 
			let GSPlayer = GrapplePlayer(Players[consoleplayer].mo);
			if(GSPlayer){
				GSPlayer.DrawPlane();
			}
		}
		
	}

	
	
	
}