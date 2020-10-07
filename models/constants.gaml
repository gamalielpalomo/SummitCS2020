/**
* Name: constants
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model constants

global{
	date starting_date <- date([2020,10,8,0,0,0]);
	file mask_file <- file("../includes/poligono_ae.shp"); 
	file roads_file <- file("../includes/roads.shp");
	file blocks_file <- file("../includes/blocks.shp");
	file buildings_file <- file("../includes/buildings.shp");
	file grids_file <- file("../includes/reticula.shp");
	file bus_file <- file("../includes/bus_stops.shp");
	image_file house_icon <- image_file("../includes/img/home.png");
	image_file bus_icon <- image_file("../includes/img/bus_stop.png");
}
