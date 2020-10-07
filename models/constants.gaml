/**
* Name: constants
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model constants

global{
	file mask_file <- file("../includes/world_shape.shp"); 
	file roads_file <- file("../includes/roads.shp");
	file blocks_file <- file("../includes/blocks_extended.shp");
	image_file house_icon <- image_file("../includes/img/home.png");
}
