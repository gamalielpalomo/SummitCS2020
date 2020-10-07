/**
* Name: summit
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model summit

import "constants.gaml"

global{
	geometry shape <- envelope(roads_file);
	graph road_network;
	init{
		create road from: roads_file;
		create blocks from:blocks_file;
		road_network <- as_edge_graph(road);
	}	
}
species road{
	aspect default{
		draw shape color:#gray;
	}	
}
grid cells width:5 height:10{
	aspect default{
		draw shape color:rgb(100,100,100,0.1) border:#white width:2.0;
	}
}
species blocks{
	aspect default{
		draw shape color:rgb (108, 82, 235,0.5);
	}
}

experiment simulation type:gui{
	output{
		display "main"{
			species road aspect:default;
			species blocks aspect:default;
			species cells aspect:default;
		}
	}
}