/**
* Name: summit
* Based on the internal empty template. 
* Author: Gamaliel Palomo, Liliana Durán, Mónica Gómez and Mario Siller
* Tags: 
*/
model summit

import "constants.gaml"

global{
	geometry shape <- envelope(mask_file);
	graph road_network;
	list<cells> useful_cells;
	init{
		step <- 10#second;
		create road from: roads_file;
		create blocks from:blocks_file;
		create sector from:grids_file;
		road_network <- as_edge_graph(road);
		create building from:buildings_file;
		ask building{
			create people number:1+rnd(3){
				home <- myself;
				location <- home.location;
			}
		}
		ask cells - useful_cells{
			do die;
		}
		useful_cells<-nil;
	}	
}

species people skills:[moving]{
	building home;
	point target;
	path path_to_follow;
	init{
		target <- any_location_in(one_of(sector));
	}
	reflex mobility{
		loop while: path_to_follow = nil{
			target <- any_location_in(one_of(sector));
			path_to_follow <- path_between(road_network,location,target);
		}
		if target = location{
			target <- any_location_in(one_of(sector));
			path_to_follow <- path_between(road_network,location,target);
		}
		do follow path:path_to_follow;
	}
	aspect default{
		draw circle(3) color:#yellow;
	}
}

species road{
	aspect default{
		draw shape color:rgb(20,20,20,0.8) width:15.0;
	}	
}

grid cells width:5 height:10{
	rgb cell_color <- rgb(0,0,0,0);
	list<blocks> blocks_inside -> {blocks inside self};
	bool flgPrint <- true;
	
	aspect default{
		draw shape color:cell_color border:rgb(255,255,255,0.2) width:3.0;
	}
	reflex main when: flgPrint{
		if length(blocks_inside)>0
		{
			write "Cell: "+grid_x+","+grid_y+" ---> " +blocks_inside;
		}
		
		flgPrint<-false;
	}
}

species blocks{
	init{
		cells parent_cell <- one_of(cells where(each overlaps self));
		if not (parent_cell in useful_cells){
			useful_cells <+ parent_cell;
		}	
	}
	
	aspect default{
		draw shape color:rgb (108, 82, 235,0.2);
	}
}

species building{
	init{
		cells parent_cell <- one_of(cells where(each overlaps self));
	}
	aspect default{
		draw shape color:rgb (81, 188, 58,255) depth:10;
		//draw house_icon size:80;
	}
}

species sector{
	aspect default{
		draw shape color:rgb(50,50,50,0.2) border:#white width:1.0;
	}
}

experiment simulation type:gui{
	output{
		display "main" background:#black draw_env:false{
			species road aspect:default;
			species sector aspect:default;
			species people aspect:default;
			//species blocks aspect:default refresh:false;
			species building aspect:default refresh:false;
			//species cells aspect:default;
		}
	}
}