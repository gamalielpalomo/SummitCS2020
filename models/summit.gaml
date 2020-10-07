/**
* Name: summit
* Based on the internal empty template. 
* Author: Gamaliel Palomo, Liliana Durán, Mónica Gómez and Mario Siller
* Tags: 
*/


model summit

import "constants.gaml"

global{
	geometry shape <- envelope(blocks_file);
	graph road_network;
	init{
		step <- 10#second;
		create road from: roads_file;
		create blocks from:blocks_file;
		road_network <- as_edge_graph(road);
		create building number:5;
		create people number:200;
	}	
}

species people skills:[moving]{
	point target;
	path path_to_follow;
	init{
		location <- any_location_in(one_of(blocks));
		target <- any_location_in(one_of(blocks));
	}
	reflex mobility{
		loop while: path_to_follow = nil{
			target <- any_location_in(one_of(blocks));
			path_to_follow <- path_between(road_network,location,target);
		}
		if target = location{
			target <- any_location_in(one_of(road));
			path_to_follow <- path_between(road_network,location,target);
		}
		do follow path:path_to_follow;
	}
	aspect default{
		draw circle(6) color:#yellow;
	}
}

species road{
	aspect default{
		draw shape color:#gray;
	}	
}

grid cells width:5 height:10{
	rgb cell_color <- rgb(0,0,0,0);
	list<blocks> blocks_inside -> {blocks inside self};
	bool flgPrint <- true;
	
	aspect default{
		draw shape color:cell_color border:#white width:2.0;
	}
	
	reflex main when: flgPrint{
		write "Cell: "+grid_x+","+grid_y+" ---> " +blocks_inside;
		flgPrint<-false;
	}
}

species blocks{
	init{
		cells parent_cell <- one_of(cells where(each overlaps self));
		ask parent_cell{
			cell_color <- rgb(100,50,50,0.2);
		}		
	}
	
	aspect default{
		draw shape color:rgb (108, 82, 235,0.2);
	}
}

species building{
	cells parent_cell <- one_of(cells where(each overlaps self));
	aspect default{
		draw shape color:#darkturquoise;
	}
}

experiment simulation type:gui{
	output{
		display "main" background:#black draw_env:false{
			species road aspect:default;
			species people aspect:default;
			species blocks aspect:default;
			species building aspect:default;
			species cells aspect:default;
		}
	}
}