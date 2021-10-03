//Set directory to save results in table to use for analysis
#@ File (style="directory") imageFolder;
dir = File.getDefaultDir;
dir = replace(dir,"\\","/");

//Get pixel dimensions
setTool("hand");
waitForUser("Get pixel dimensions","Click on the non-annotated input image to get the pixel dimensions\nthen press OK");
getPixelSize(unit, pixelWidth, pixelHeight);
getVoxelSize(width, height, depth, unit);
pixel_area = pixelWidth*pixelHeight;

waitForUser("Starting frame","Put the annotated image at the slice from where the process should start\nthen press OK");

setTool("multipoint");
waitForUser("Select object and background","click on what you want to measure the circularity of in the annoatetd image, then on the background\nand then press OK");
getSelectionCoordinates(xpoints, ypoints);
foreground = getValue(xpoints[0], ypoints[0]);
background = getValue(xpoints[1], ypoints[1]);
setTool("hand");

source = getTitle();

//Get image dimensions
w = getWidth();
h = getHeight();

sn = getSliceNumber();

slice_array = newArray();
depth_array = newArray();

slice_number = sn;

//Get mean and stdDev distances of all slices
mean_distances_all_slices = newArray();
stdDev_distances_all_slices = newArray();
//Get mean and stdDev distances of all slices
mean_distances_all_slices_normalised = newArray();
stdDev_distances_all_slices_normalised = newArray();

//Get distances of all slices
distances_all_slices = newArray();
//Get normalised distances of all slices
distances_all_slices_normalised = newArray();

//Analyse all slices
for (z=sn-1;z<nSlices;z++) {
	setColor(65535,65535,65535);
	//Dendrite pixel count
	n = 0;
	edge_n = 0;
	//Get coordinates of dendrite pixels
	xcorr = 0;
	ycorr = 0;
	//Get the x and y coordiantes of the periphery of the annotated image and annotate the periphery
	annotated_edge_x = newArray();
	annotated_edge_y = newArray();
	//Loop for every pixel in current slice
	for (x=0;x<w;x++){
		for (y=0;y<h;y++){
			if (getPixel(x,y) == foreground){
				n += 1;
				xcorr += x;
				ycorr += y;
				if (getPixel(x,y) == foreground){
					if (getPixel(x+1,y) == background){
					annotated_edge_x = Array.concat(annotated_edge_x,x);
					annotated_edge_y = Array.concat(annotated_edge_y,y);
					edge_n += 1;
					} else if (getPixel(x-1,y) == background){
					annotated_edge_x = Array.concat(annotated_edge_x,x);
					annotated_edge_y = Array.concat(annotated_edge_y,y);
					edge_n += 1;
					} else if (getPixel(x,y+1) == background){
					annotated_edge_x = Array.concat(annotated_edge_x,x);
					annotated_edge_y = Array.concat(annotated_edge_y,y);
					edge_n += 1;
					} else if (getPixel(x,y-1) == background){
					annotated_edge_x = Array.concat(annotated_edge_x,x);
					annotated_edge_y = Array.concat(annotated_edge_y,y);
					edge_n += 1;
					}
				}
			}
		}
	}
	//Retrieve slice depth
	slice_array = Array.concat(slice_array,slice_number);
	slice_depth = (slice_number-1)*depth; 
	depth_array = Array.concat(depth_array,slice_depth);
	//Get centroid
	x_centre = xcorr/n;
	y_centre = ycorr/n;
	//Make perfect circle image
	newImage("distance_stack_V2", 16, w, h, 1);
	diameter = 1.12475*Math.pow(n,0.50030);
	circle_start_x = x_centre-(diameter/2);
	circle_start_y = y_centre-(diameter/2); 
	fillOval(circle_start_x, circle_start_y, diameter, diameter);
	//Set foreground and background
	foreground_circle = getValue(x_centre,y_centre);
	background_circle = getValue(0,0);
	//Get the x and y coordiantes of the periphery of the annotated image and annotate the periphery
	circle_edge_x = newArray();
    circle_edge_y = newArray();
    edge_pixels = 0;
	//Loop for every pixel in current slice for periphery coordinates
	for (x=0;x<w;x++){
		for (y=0;y<h;y++){
			if (getPixel(x,y) == foreground_circle){
				if (getPixel(x+1,y) == background_circle){
				circle_edge_x = Array.concat(circle_edge_x,x);
				circle_edge_y = Array.concat(circle_edge_y,y);
				edge_pixels += 1;
				} else if (getPixel(x-1,y) == background_circle){
				circle_edge_x = Array.concat(circle_edge_x,x);
				circle_edge_y = Array.concat(circle_edge_y,y);
				edge_pixels += 1;
				} else if (getPixel(x,y+1) == background_circle){
				circle_edge_x = Array.concat(circle_edge_x,x);
				circle_edge_y = Array.concat(circle_edge_y,y);
				edge_pixels += 1;
				} else if (getPixel(x,y-1) == background_circle){
				circle_edge_x = Array.concat(circle_edge_x,x);
				circle_edge_y = Array.concat(circle_edge_y,y);
				edge_pixels += 1;	
				}
			}
		}
	}
	//Annotate the periphery
	for (x=0;x<w;x++){
		for (y=0;y<h;y++){
			setPixel(x,y,background_circle);
		}
	}
	for (i=0;i<edge_pixels;i++){
		setPixel(circle_edge_x[i],circle_edge_y[i],foreground_circle);
	}
	for (i=0;i<edge_n;i++){
		setPixel(annotated_edge_x[i],annotated_edge_y[i],foreground_circle);
	}
	//Get all closest distances in one slice
	all_distances_one_slice = newArray();
	all_distances_one_slice_normalised = newArray(); 
	//Iterate for all points in the periphery of the annotated area
	for (q=0;q<edge_n;q++) {
		//Iterate for every pixel in the periphery of the annotation to get minimum
		one_annotated_to_all_circle = newArray();
		for (i=0;i<edge_pixels;i++) {
			one_annotated_to_one_circle = Math.sqrt(Math.sqr(annotated_edge_x[q] - circle_edge_x[i]) + Math.sqr(annotated_edge_y[q] - circle_edge_y[i]));
			one_annotated_to_all_circle = Array.concat(one_annotated_to_all_circle,one_annotated_to_one_circle);
		}
		Array.getStatistics(one_annotated_to_all_circle, min, max, mean, stdDev);
		//Add to array of slice
		all_distances_one_slice = Array.concat(all_distances_one_slice,min);
		//Add to array of slice normalised to calculate overal mean and stdDev
		all_distances_one_slice_normalised = Array.concat(all_distances_one_slice_normalised,(min/(diameter/2)));
		//Add to array of all slices
		//Find index of minimum for visualisation
		for (i=0;i<edge_pixels;i++) {
			if (Math.sqrt(Math.sqr(annotated_edge_x[q] - circle_edge_x[i]) + Math.sqr(annotated_edge_y[q] - circle_edge_y[i])) == min) {
				setColor(255,255,0);
				drawLine(annotated_edge_x[q],annotated_edge_y[q],circle_edge_x[i],circle_edge_y[i]);	
			}
		}
	}
	distances_all_slices = Array.concat(distances_all_slices,all_distances_one_slice);
	//Add to array of slice normalised to calculate overal mean and stdDev
	distances_all_slices_normalised = Array.concat(distances_all_slices_normalised,all_distances_one_slice_normalised);		
	//Get statistics of one slice
	Array.getStatistics(all_distances_one_slice, min, max, mean, stdDev);
	//Add to all slices
	mean_distances_all_slices = Array.concat(mean_distances_all_slices,mean);
	stdDev_distances_all_slices = Array.concat(stdDev_distances_all_slices,stdDev);
	//Get statistics of one slice normalised
	Array.getStatistics(all_distances_one_slice_normalised, min, max, mean, stdDev);
	//Add to all slices normalised
	mean_distances_all_slices_normalised = Array.concat(mean_distances_all_slices_normalised,mean);
	stdDev_distances_all_slices_normalised = Array.concat(stdDev_distances_all_slices_normalised,stdDev);
    if (slice_number > sn) {
    	rename("new_slice");
		run("Concatenate...", "  title=distance_stack_V2 image1=distance_stack_V2 image2=new_slice image3=[-- None --]");
    }
	selectImage(source);
	run("Next Slice [>]");
	slice_number += 1;
}

mean_all_distances_all_slices = newArray();
mean_all_normalised_distances_all_slices = newArray();
stdDev_all_distances_all_slices = newArray();
stdDev_all_normalised_distances_all_slices = newArray();
//Get statistics of all slice
Array.getStatistics(distances_all_slices, min, max, mean, stdDev);
print(mean,stdDev);
mean_all_distances_all_slices = Array.concat(mean_all_distances_all_slices,mean);
stdDev_all_distances_all_slices = Array.concat(stdDev_all_distances_all_slices,stdDev);
//Get statistics of all slice normalised
Array.getStatistics(distances_all_slices_normalised, min, max, mean, stdDev);
print(mean,stdDev);
mean_all_normalised_distances_all_slices = Array.concat(mean_all_normalised_distances_all_slices,mean);
stdDev_all_normalised_distances_all_slices = Array.concat(stdDev_all_normalised_distances_all_slices,stdDev);

Plot.create("Circularity", "depth in microns", "normalised mean", depth_array, mean_distances_all_slices_normalised);
Plot.add("line", depth_array, stdDev_distances_all_slices_normalised, "95% confidence interval");

save_option = getBoolean("Want to save results?");
if (save_option == 1){
//Make a table containing the arrays
Table.create("Circularity_V1");
Table.setColumn("slice",slice_array);
Table.setColumn("depth",depth_array);
Table.setColumn("mean",mean_distances_all_slices_normalised);
Table.setColumn("stDev",stdDev_distances_all_slices_normalised);
Table.setColumn("mean_all_slices",mean_all_distances_all_slices);
Table.setColumn("stdDev_all_slices",stdDev_all_distances_all_slices);
Table.setColumn("normalised_mean_all_slices",mean_all_normalised_distances_all_slices);
Table.setColumn("normalised_stdDev_all_slices",stdDev_all_normalised_distances_all_slices);
Table.save(dir+"Dendrite_Cross-sectional_Area_Circularity"+".csv");
}