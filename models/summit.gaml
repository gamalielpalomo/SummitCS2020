/**
* Name: Model for the interactions of people and environment.
* Based on the internal empty template. 
* Author: Gamaliel Palomo, Liliana Durán, Mónica Gómez and Mario Siller
* Tags: Interactions, social fabric
*/
model summit

import "constants.gaml"

global{
	bool show_sectors parameter: "Show sectors" category:"Visualization" <- false;
	bool show_bus parameter: "Show bus stops" category:"Visualization" <- false;
	bool show_isolation parameter: "Show isolation" category:"Visualization" <- false;
	
	geometry shape <- envelope(mask_file);
	graph road_network;
	
	//Graph related variables
	float beta_index;
	
	init{
		step <- 20#second;
		create road from: roads_file;
		create blocks from:blocks_file;
		create sector from:grids_file;
		create bus_stops from:bus_file;
		road_network <- as_edge_graph(road);
		create building from:buildings_file;
		ask building{
			create people number:1+rnd(3){
				home <- myself;
				location <- home.location;
			}
		}
	}
	
	user_command "create park here"{
		blocks aux_block <- blocks closest_to #user_location;
		create park{
			shape <- aux_block.shape;
		}
	}
	
	reflex connectivity when:every(1#day){
		beta_index <- beta_index(one_of(building).my_graph);
	}
	
	reflex populate_neighborhood when:every(1#day){
		int houses_to_build <- rnd(10);
		ask sector{
			do calculate_density;
		}
		 
		list<sector> ordered_sector <- sector sort_by (each.no_building);
		ordered_sector <- houses_to_build last ordered_sector;
		ask ordered_sector
		{
			do build sect:self;
		}
	}
	
}


species people skills:[moving]{
	
	//Agenda related variables
	building home;
	building target;
	bool foreign; //This agent does not live in the community
	bool works_out; //This agent works out of the community
	
	map<date,agent> agenda_day;
	
	path path_to_follow;
	init{
		target <- one_of(sector) as building;
		foreign <- false;
		works_out <- flip(0.5);
	}
	reflex create_new_agenda when:empty(agenda_day){
		int hours_for_activities <- rnd(4,14);
		int hour_for_go_out <- rnd(0,24-hours_for_activities);
		int nb_activities <- rnd(2,5);
		int hours_per_activity <- int(hours_for_activities/nb_activities);
		int sum <- 0;
		loop times:nb_activities{
			agenda_day <+ (date(current_date.year,current_date.month, hour_for_go_out+sum>=24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::works_out?one_of(bus_stops):one_of(building+park));
			sum <- sum + hours_per_activity;
		}
		agenda_day <+ (date(current_date.year,current_date.month,hour_for_go_out+sum>24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::home);
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])){
		target <- agenda_day.values[0] as building;
		agenda_day>>first(agenda_day);
	}
	reflex mobility when:target!=location{
		do goto target:target on:road_network;
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


species blocks{
	aspect default{
		draw shape color:rgb (108, 82, 235,0.2);
	}
}

species edge_agent parent: base_edge {
    aspect base {
    	if show_isolation{
    		draw shape color: #blue;
    	}
    }
}

species building parent:graph_node edge_species:edge_agent{
	float isolation <- 0.0;
	bool flgCreated <- false;
	bool related_to (building other){
		using topology(world){
			return (location distance_to other < 100#m);	
		}
    }
    
	aspect default{
		if flgCreated
		{
			draw square(7#m) color:rgb (81, 188, 58,255) depth:10;
		}
		else
		{
			draw shape color:rgb (81, 188, 58,255) depth:10;
		}
		draw shape color:rgb (81, 188, 58,255) depth:10;		
		//draw house_icon size:80;
	}
}

species park{
	aspect default{
		draw shape color:rgb (27, 154, 27,255) border:#white width:2.0;
		draw "PARK" color:#white;
	}
}

species sector{
	list<building> buildings -> {building inside self};
	int no_building<-0;
	bool flgFull <- false;
   
	
	aspect default{
		if show_sectors{
			draw shape color:rgb(50,50,50,0.2) border:#white width:1.0;
			draw self.name color:#white;
		}
	}
	
	// metodo que puede usarse para calcular una metrica de construcción
	action calculate_density
	{
		no_building <- length(agents_inside(self));
	}
	
	
	
	// constrye una nueva casa
	action build(sector sect){	
		create building number:1{
			location <- any_location_in(sect);
			flgCreated <- true;
			create people number:1+rnd(3){
				home <- myself;
				location <- home.location;
			}
		}
	}
	
	
}

species bus_stops{
	aspect default{
		//draw shape color:rgb(50,150,50,0.2) width:10;
		if show_bus{
			draw bus_icon size:60;	
		}
		//draw "PUBLIC TRANSPORTATION" color:#white;
	}
}

experiment simulation type:gui{
	output{
		display "main" background:#black draw_env:false{
			species road aspect:default;
			species sector aspect:default;
			species park aspect:default;
			species people aspect:default;
			species bus_stops aspect:default;
			//species blocks aspect:default refresh:false;
			species building aspect:default refresh:false;
			species edge_agent aspect: base;
			overlay position: { 40#px, 30#px } size: { 0,0} background: # black transparency: 0.5 border: #black {
				string minutes;
				if current_date.minute < 10{minutes <- "0"+current_date.minute; }
				else {minutes <- string(current_date.minute);}
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",20,#plain);
				draw ":0123456789" at:{ 0#px, 0#px} color:rgb(0,0,0,0) font:font("Arial",55,#bold);
				draw ".:-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()[],>=" at: {0#px,0#px} color:rgb(0,0,0,0) font:font("Arial",19,#bold);
				draw "People: " +  length(people) at: { 20#px, 60#px } color: #white font:font("Arial",19,#bold);
				draw ""+current_date.hour+":"+minutes at:{ 20#px, 20#px} color:#white font:font("Arial",55,#bold);
				draw "Beta index: "+ beta_index at:{20#px, 100#px} color: #white font:font("Arial",19,#bold);
				
			}
		}
	}
}