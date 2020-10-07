/**
* Name: constants
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model constants

global{
	file mask_file <- file("../includes/poligono_ae.shp"); 
	file roads_file <- file("../includes/roads.shp");
	file blocks_file <- file("../includes/blocks.shp");
	file buildings_file <- file("../includes/buildings.shp");
	file grids_file <- file("../includes/reticula.shp");
	image_file house_icon <- image_file("../includes/img/home.png");
}
