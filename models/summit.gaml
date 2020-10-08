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
	string sectors_var parameter: "Variable to show" category:"Visualization" <- "buildings" among:["buildings","people"];
	bool show_bus parameter: "Show bus stops" category:"Visualization" <- false;
	bool show_isolation parameter: "Show isolation" category:"Visualization" <- false;
	bool show_interactions parameter: "Show interactions" category:"Visualization" <- false;
	
	geometry shape <- envelope(mask_file);
	graph road_network;
	map<road, float> weight_map;
	
	float interaction_distance<-30#m;
	int count_interactions <- 0;
	//Graph related variables
	float beta_index;
	
	
	init{
		step <-20#second;
		create road from: roads_file;
		create blocks from:blocks_file;
		create building from:buildings_file;
		ask building{
			flgCreated<-false;
			create people number:1+rnd(3){
				home <- myself;
				location <- home.location;
			}
		}
		create sector from:grids_file;
		create bus_stops from:bus_file;
		weight_map <- road as_map (each::each.shape.perimeter);
		road_network <- as_edge_graph(road) with_weights weight_map;
		
		
	}
	
	user_command "create park here"{
		blocks aux_block <- blocks closest_to #user_location;
		create park{
			shape <- aux_block.shape;
		}
	}
	
	reflex connectivity when:every(3#hour){
		beta_index <- beta_index(one_of(building).my_graph) with_precision 2;
	}
	
	reflex populate_neighborhood when:every(3#hour){
		int houses_to_build <- rnd(10);
		ask sector{
			do calculate_density;
		}
		
		list<sector> ordered_sector <- sector sort_by (each.density);
		ordered_sector <- houses_to_build last ordered_sector;
		ask ordered_sector
		{
			do build sect:self;
		}
	}
	
	reflex count_interactions when:every(1#minute){
		count_interactions <- people sum_of length(each.interactions);
	}
	
}


species people skills:[moving]{
	
	//Agenda related variables
	building home;
	point target;
	bool foreign; //This agent does not live in the community
	bool works_out; //This agent works out of the community
	
	map<date,agent> agenda_day;
	list<people> interactions;
	
	
	path path_to_follow;
	init{
		foreign <- false;
		works_out <- flip(0.5);
	}
	reflex update_interactions when:every(1#minute){
		interactions <- [];
		if (bus_stops at_distance(2)) = [] or (bus_stops at_distance(2)) = nil or empty(bus_stops at_distance(2)){
			using topology(world){
				interactions <- people at_distance interaction_distance;	
			}		
		}
		
	}
	
	species activity{
		string act_name;//Activities to perform: one_of("leisure","work","home")
	}
	
	reflex create_new_agenda when:empty(agenda_day){
		int hours_for_activities <- rnd(4,14);
		int hour_for_go_out <- rnd(0,24-hours_for_activities);
		int nb_activities <- rnd(2,5);
		int hours_per_activity <- int(hours_for_activities/nb_activities);
		int sum <- 0;
		ask activity{do die;}
		loop times:nb_activities{
			create activity{
				act_name<-one_of("leisure","work","home");
				if act_name = "leisure"{
					if not empty(park){location <- any_location_in(park closest_to self);}
					else{location <- flip(0.5)?home.location:(bus_stops closest_to self).location;}
				}
				else if act_name = "work"{
					location <- flip(0.8)?(bus_stops closest_to self).location:any_location_in(one_of(sector));
				}
				else{location <- home.location;}
			}
			agenda_day <+ (date(current_date.year,current_date.month, hour_for_go_out+sum>=24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::last(activity));
			sum <- sum + hours_per_activity;
		}
		create activity{act_name <- "home";location<-home.location;}
		agenda_day <+ (date(current_date.year,current_date.month,hour_for_go_out+sum>24?current_date.day+1:current_date.day,hour_for_go_out+sum>=24?mod(hour_for_go_out+sum,24):hour_for_go_out+sum, rnd(0,59),0)::last(activity));
	}
	reflex update_activity when:not empty(agenda_day) and (after(agenda_day.keys[0])){
		target <- (agenda_day.values[0] as activity).location;
		agenda_day>>first(agenda_day);
	}
	reflex mobility when:target!=location{
		do goto target:target on:road_network;
	}
	aspect default{
		draw circle(3) color:#yellow;
		if show_interactions{
			loop contact over:interactions{
				draw curve(location, contact.location,1.0, 200, 90) color:rgb (255, 255, 255,255);
			}
		}
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
	bool flgCreated;
	
	bool related_to (building other){
		using topology(world){
			return (location distance_to other < 100#m);	
		}
    }
    
	aspect default{
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
	float no_building <- 0.0;
	float no_bus_stops <- 0.0;
	float no_parks <- 0.0;
	float density<-0.0;
	bool flgFull <- false;
	int people_inside;
   
	
	aspect default{
		if show_sectors{
			if sectors_var = "buildings"{
				draw shape color:rgb(50,50*density/10+50,50,0.4) border:#white width:1.0;
				draw self.name color:#white;
			}
			else{
				draw shape color:rgb(50,50*people_inside/10+50,50,0.2) border:#white width:1.0;
				draw self.name color:#white;
			}
		}
	}
	
	// metodo que puede usarse para calcular una metrica de construcción
	action calculate_density
	{
		list<building> n_houses <- building inside self;
		no_building <- float(length(n_houses));
		
		density <- no_building;
	}
	
	reflex update_people_inside when: sectors_var="people" and show_sectors{
		people_inside <- length(people inside self);
	}
	
	// constrye una nueva casa
	action build(sector sect){	
		create building number:1{
			shape <- one_of(building).shape;
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
		layout #split;
		display "main" background:#black type:opengl draw_env:false{
			species road aspect:default;
			species sector aspect:default;
			
			species people aspect:default;
			species bus_stops aspect:default;
			//species blocks aspect:default refresh:false;
			species building aspect:default;
			species edge_agent aspect: base;
			species park aspect:default;
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
				draw "Buildings: "+length(building) at:{20#px, 140#px} color: #white font:font("Arial",19,#bold);
				draw "Interactions: "+count_interactions at:{20#px, 160#px} color: #white font:font("Arial",19,#bold);
			}
		}
		display "chart" background:#black draw_env:false type:opengl{
			chart "main" color:#white background:#black title_font:font("arial",26,#bold) legend_font:font("arial",24,#plain) y_label:"Value"{
				data "people" value:length(people)  color:#yellow;
				data "interactions" value:count_interactions color:#blue;
				data "beta index" value:beta_index  color:#red;
				data "buildings" value:length(building)  color:#gamaorange;
			}
		}
		
	}

}