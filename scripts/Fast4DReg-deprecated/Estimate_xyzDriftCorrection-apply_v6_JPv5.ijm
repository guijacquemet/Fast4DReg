
run("Close All");
print("\\Clear");
run("Collect Garbage");

// select file to be corrected
#@ File (label="Select the file to be corrected", style="open") my_file_path ;

//settings for xy-drif correction
#@ String  (value="-----------------------------------------------------------------------------", visibility="MESSAGE") hint1;
#@ boolean (label = "<html><b>xy-drift correction (if not don't fill values)</b></html>") XY_registration ; 
#@ String(label = "Projection type", choices={"Max Intensity","Average Intensity"}, style="listBox") projection_type_xy ;

#@ Integer (label="Time averaging (default 100, 1 - disables)", min=1, max=100, style="spinner") time_xy ;

#@ Integer (label="Maximum expected drift (pixels, 0 - auto)", min=0, max=auto, style="spinner") max_xy ;

#@ String (label = "Reference frame", choices={"first frame (default, better for fixed)" , "previous frame (better for live)"}, style="listBox") reference_xy ;

#@ boolean (label = "Crop output") crop_output ; 

//settings for z-drif correction

#@ String  (value="-----------------------------------------------------------------------------", visibility="MESSAGE") hint2;
#@ boolean (label = "<html><b>z-drift correction (if not don't fill values)</b></html>") z_registration ; 
#@ String(label = "Projection type", choices={"Max Intensity","Average Intensity"}, style="listBox") projection_type_z ;

#@ String(label = "Reslice mode", choices={"Top","Left"}, style="listBox") reslice_mode ;

#@ Integer (label="Time averaging (default 100, 1 - disables)", min=1, max=100, style="spinner") time_z ;

#@ Integer (label="Maximum expected drift (pixels, 0 - auto)", min=0, max=auto, style="spinner") max_z ;

#@ String (label = "Reference frame", choices={"first frame (default, better for fixed)" , "previous frame (better for live)"}, style="listBox") reference_z ;

#@ boolean (label = "Extend stack to fit") extend_stack_to_fit ; 

#@ boolean (label = "Save RAM") ram_conservative_mode ; 

#@ String  (value="-----------------------------------------------------------------------------", visibility="MESSAGE") hint2;

//set file paths
filename_no_extension = File.getNameWithoutExtension(my_file_path);
settings_file_path = File.getDirectory(my_file_path)+filename_no_extension+"_settings.csv"; 
DriftTable_path_XY = File.getDirectory(my_file_path)+filename_no_extension+"-"+projection_type_xy+"_xy_"; //added xy in file name /JP
DriftTable_path_Z = File.getDirectory(my_file_path)+filename_no_extension+"-"+projection_type_z+"-"+reslice_mode+"_z_"; //z added to the name

// create a new table
// set columns
setResult("Setting", 0, "File Name");
setResult("Value", 0, filename_no_extension);

setResult("Setting", 1, "xy-registration");
setResult("Value", 1, XY_registration);

setResult("Setting", 2, "xy-projection type");
setResult("Value", 2, projection_type_xy);

setResult("Setting", 3, "xy-time averaging");
setResult("Value", 3, time_xy);

setResult("Setting", 4, "xy-maximum expected drift");
setResult("Value", 4, max_xy);

setResult("Setting", 5, "xy-reference frame");
setResult("Value", 5, reference_xy);

setResult("Setting", 6, "Crop output");
setResult("Value", 6, crop_output);

setResult("Setting", 7, "z-registration");
setResult("Value", 7, z_registration);

setResult("Setting", 8, "z-projection type");
setResult("Value", 8, projection_type_z);

setResult("Setting", 9, "z-reslice mode");
setResult("Value", 9, reslice_mode);

setResult("Setting", 10, "z-time averaging");
setResult("Value", 10, time_z);

setResult("Setting", 11, "z-maximum expected drift");
setResult("Value", 11, max_z);

setResult("Setting", 12, "z-reference frame");
setResult("Value", 12, reference_z);

setResult("Setting", 13, "Extend stack to fit");
setResult("Value", 13, extend_stack_to_fit);

setResult("Setting", 14, "Save RAM");
setResult("Value", 14, ram_conservative_mode);

setResult("Setting", 15, "xy-drift table path");
setResult("Value", 15, DriftTable_path_XY +"DriftTable.njt");

setResult("Setting", 16, "z-drift table path");
setResult("Value", 16, DriftTable_path_Z +"DriftTable.njt");

saveAs("Results", settings_file_path);
//run("Close");
close("Results");

//======================================================================
// ----- Let's go ! -----
IJ.log("------------------");
t_start = getTime();

//open file
filename_no_extension = File.getNameWithoutExtension(my_file_path);
IJ.log(my_file_path);
run("TIFF Virtual Stack...", "open="+my_file_path);

setBatchMode(true); 
thisTitle = getTitle();

//======================================================================
// ----- Estimating the xy-correction from the resliced projection -----

if (XY_registration){
	// make projection
	getDimensions(width, height, channels, slices, frames);
	run("Z Project...", "projection=["+projection_type_xy+"] all");
	rename(projection_type_xy+" projection_"+filename_no_extension);
	//setBatchMode("show");

	//path to drift table moved up
	//DriftTable_path_XY = File.getDirectory(my_file_path)+filename_no_extension+"-"+projection_type_xy+"_xy_"; //added xy in file name /JP
	IJ.log(DriftTable_path_XY);
	
	//estimate x-y drift
	run("Estimate Drift", "time_xy max_xy reference_xy show_drift_plot apply choose=["+DriftTable_path_XY+"]");
	rename("DriftCorrOutput_XY");

	//save drift plots
	selectWindow("Drift-X");
	saveAs("Tiff", my_file_path+"_Drift-plot-X");
	//setBatchMode("show");

	selectWindow("Drift-Y");
	saveAs("Tiff", my_file_path+"_Drift-plot-Y");
	//setBatchMode("show");	

// ----- Applying the xy-correction from the resliced projection -----

	for (i = 0; i < slices; i++) {
		showProgress(i, slices);

		selectWindow(thisTitle);
		run("Duplicate...", "title=DUP duplicate slices="+(i+1));
		run("32-bit");
		run("Correct Drift", "choose=["+DriftTable_path_XY+"DriftTable.njt]");
		selectWindow("DUP - drift corrected");
		rename("SLICE");
	
	if (i==0){
		rename("AllStarStack");}
	else {
		// This is potentially what makes it so slow as it needs to dump and recreate the stack every time
		run("Concatenate...", "  image1=AllStarStack image2=SLICE image3=[-- None --]");
		rename("AllStarStack");}

	close("DUP");	

}

	selectWindow("AllStarStack");
	print(width, height, channels, slices, frames);

	setBatchMode("show");
	run("Stack to Hyperstack...", "order=xyctz channels=1 slices="+slices+" frames="+frames+" display=Color");
	
	run("Enhance Contrast", "saturated=0.35");
	rename(filename_no_extension+"_xyCorrected");
	Corrected_path_xy = File.getDirectory(my_file_path)+filename_no_extension+"_xyCorrected"; //z added to the name
	print("Corrected_path_xy");
	IJ.log(Corrected_path_xy);

// crops image when doing xy-correction and if z-estiatin is run //JP 	 
	if (crop_output || z_registration) {	
		minmaxXYdrift = getMinMaxXYFromDriftTable_xy(DriftTable_path_XY+"DriftTable.njt");
		print(DriftTable_path_XY+"DriftTable.njt");
		print(minmaxXYdrift[0]);
		print(minmaxXYdrift[1]);
		print(minmaxXYdrift[2]);
		print(minmaxXYdrift[3]);

	selectWindow(filename_no_extension+"_xyCorrected");
	width = getWidth();
	height = getHeight();
	 
	new_width = width - Math.ceil(minmaxXYdrift[1]) + Math.ceil(minmaxXYdrift[0]);
	new_height = height - Math.ceil(minmaxXYdrift[3]) + Math.ceil(minmaxXYdrift[2]);
	
	makeRectangle(Math.ceil(minmaxXYdrift[1]), Math.ceil(minmaxXYdrift[3]), new_width, new_height);
	run("Crop");
	}

	// Save intermediate file xy-correct //JP 	 
	saveAs("Tiff", Corrected_path_xy);
	close("*");
}
//======================================================================

if (z_registration) {
	
	// ----- opening the correct file-----	
	if (!XY_registration){
		run("TIFF Virtual Stack...", "open="+my_file_path);
	} else {
		run("TIFF Virtual Stack...", "open="+Corrected_path_xy+".tif");
	}
	
// ----- Reslicing for z-projection estimation-----	
	getVoxelSize(width, height, depth, unit);
	run("Reslice [/]...", "output="+depth+" start="+reslice_mode+" avoid");
	rename("DataRescliced");
	getDimensions(width, height, channels, slices, frames);
	scale_factor = round(width/height);
	print("Scaling factor: "+scale_factor);
	
	setBatchMode("show");
	
	//======================================================================
	// ----- Estimating the z correction  from the resliced projection -----
	run("Z Project...", "projection=["+projection_type_z+"] all");
	rename(projection_type_z+" "+reslice_mode+" projection_"+filename_no_extension);
	setBatchMode("show");
	
	run("Scale...", "x=1.0 y="+scale_factor+" z=1.0 width="+width+" height="+(scale_factor*width)+" depth="+frames+" interpolation=Bicubic average process create");

	//path to drift table moved up
	//DriftTable_path_Z = File.getDirectory(my_file_path)+filename_no_extension+"-"+projection_type_z+"-"+reslice_mode+"_z_"; //z added to the name
	IJ.log(DriftTable_path_Z);
	
	run("Estimate Drift", "time_z max_z reference_z show_drift_plot apply choose=["+DriftTable_path_Z+"]"); //added Z to the dfrist table path name
	rename("DriftCorrOutput");
	
	selectWindow("Drift-X");
	//setBatchMode("show");
	
	selectWindow("Drift-Y");
	rename("Drift-Z");
	Plot.setXYLabels("time-points", "z-drift (px)");
	saveAs("Tiff", my_file_path+"_Drift-plot-Z");
	//setBatchMode("show");
	
	selectWindow("DriftCorrOutput");
	run("Scale...", "x=1.0 y="+(1/scale_factor)+" z=1.0 width="+width+" height="+height+" depth="+frames+" interpolation=Bicubic average process create");
	rename("DriftCorrected_"+projection_type_z+" "+reslice_mode+" projection_"+filename_no_extension);
	
	//edits drift tabel so that only z drift is saved
	run("Open NanoJ Table (NJT)...", "load=["+DriftTable_path_Z+"DriftTable.njt]");
	TableName = filename_no_extension+"-"+projection_type_z+"-"+reslice_mode+"_z_DriftTable.njt";
	Table.rename(TableName, "Results");
	for (i = 0; i < nResults; i++) {
		setResult("X-Drift (pixels)", i, 0);
		setResult("XY-Drift (pixels)", i, 0);
	}
	updateResults();
	run("Save Results-Table as NJT...", "save=["+DriftTable_path_Z+"DriftTable.njt]");
	
	resetDriftTable(DriftTable_path_Z+"DriftTable.njt", scale_factor);
	
	setBatchMode(false);
	run("Collect Garbage");
	
	
//------- Applying the z correction -------- 
	
setBatchMode(true);
IJ.log("Applying the correction to the stack....");

if (extend_stack_to_fit){
	minmaxZdrift = getMinMaxFromDriftTable_z(DriftTable_path_Z+"DriftTable.njt");
	padding = 2*maxOf(-minmaxZdrift[0], minmaxZdrift[1]);
	}
else {
	padding = 0;
}

selectWindow("DataRescliced");
getDimensions(width, height, channels, slices, frames);
getVoxelSize(width_realspace, height_realspace, depth_realspace, unit_realspace);
padded_height = height + padding;

if (!ram_conservative_mode){
	newImage("DataRescliced_Corrected", "32-bit black", width, padded_height, slices*frames);
	setVoxelSize(width_realspace, height_realspace, depth_realspace, unit_realspace);
	//setBatchMode("show");	
}

for (i = 0; i < slices; i++) {
	showProgress(i, slices);
	selectWindow("DataRescliced");

	if (ram_conservative_mode){
		setSlice(1);
		run("Duplicate...", "title=DUP duplicate slices=1");
	}
	else{
		run("Duplicate...", "title=DUP duplicate slices="+(i+1));
	}

	run("Canvas Size...", "width="+width+" height="+(padded_height)+" position=Center zero");
	
	run("Correct Drift", "choose=["+DriftTable_path_Z+"DriftTable.njt]");
	rename("SLICE");
	run("Hyperstack to Stack");
	
	if (ram_conservative_mode){
		if (i==0){
			rename("AllStarStack");}
		else {
			// This is potentially what makes it so slow as it needs to dump and recreate the stack every time
			run("Concatenate...", "  image1=AllStarStack image2=SLICE image3=[-- None --]");
			rename("AllStarStack");}
	}
	else {
		for (f = 0; f < frames; f++) {
			selectWindow("SLICE");
			setSlice(f+1);
			run("Select All");
			run("Copy");
			selectWindow("DataRescliced_Corrected");
			setSlice(i*frames + f+1);
			run("Paste");		
		}
	}
		
	close("DUP");

	if (ram_conservative_mode){
		selectWindow("DataRescliced");
		run("Delete Slice", "delete=slice");
	}
	else {
		close("SLICE");
	}
}

if (!ram_conservative_mode){
	close("DataRescliced");
	selectWindow("DataRescliced_Corrected");
	run("Select None");
	run("Enhance Contrast", "saturated=0.35");
}
else {
	selectWindow("AllStarStack");
}

//setBatchMode("show");
run("Stack to Hyperstack...", "order=xyctz channels=1 slices="+slices+" frames="+frames+" display=Color");
getVoxelSize(width, height, depth, unit);
run("Reslice [/]...", "output="+depth+" start=Top avoid");

if (reslice_mode == "Left"){
	run("Flip Vertically", "stack");
	run("Rotate 90 Degrees Right");
}
	
//save files here
if (!XY_registration) {
	rename(filename_no_extension+"_zCorrected"); // corrected naming from _Corrected to _zCorrected //JP
	Corrected_path_z = File.getDirectory(my_file_path)+filename_no_extension+"_zCorrected"; //z added to the name
	saveAs("Tiff", Corrected_path_z);
	} else {
	rename(filename_no_extension+"_xyzCorrected");
	Corrected_path_xyz = File.getDirectory(my_file_path)+filename_no_extension+"_xyzCorrected";
	saveAs("Tiff", Corrected_path_xyz);  
	}   

	run("Enhance Contrast", "saturated=0.35");
	setBatchMode("show");
	setBatchMode(false);
	
}

close("\\Others");
IJ.log("------");
IJ.log("Time taken: "+round((getTime()-t_start)/1000)+"s");
IJ.log("All done.");

showMessage("All DONE! Time: " +round((getTime()-t_start)/1000)+"s");

//====== THE END =======================================================

//======================================================================
// ----- Helper functions -----
function getMinMaxFromDriftTable_z(path_to_table) {
	run("Open NanoJ Table (NJT)...", "load=["+path_to_table+"]");
	Table.rename(File.getName(path_to_table), "Results");

	minmaxZdrift = newArray(2);
	minmaxZdrift[0] = 0;
	minmaxZdrift[1] = 0;

	for (i = 0; i < nResults; i++) {
		zDrift = getResult("Y-Drift (pixels)", i);
		if (zDrift < minmaxZdrift[0]) minmaxZdrift[0] = zDrift;
		if (zDrift > minmaxZdrift[1]) minmaxZdrift[1] = zDrift;
	}

	minmaxZdrift[0] = floor(minmaxZdrift[0]); 
	minmaxZdrift[1] = Math.ceil(minmaxZdrift[1]);
	close("Results");

	return minmaxZdrift;
}

//--------------------------------------------- 
function resetDriftTable(path_to_table, scale_factor) {
	run("Open NanoJ Table (NJT)...", "load=["+path_to_table+"]");
	Table.rename(File.getName(path_to_table), "Results");

	for (i = 0; i < nResults; i++) {
		zDrift = getResult("Y-Drift (pixels)", i);
		setResult("Y-Drift (pixels)", i, zDrift/scale_factor);
	}
	updateResults();

	run("Save Results-Table as NJT...", "save=["+path_to_table+"]");
	close("Results");

	return;
}

//--------------------------------------------- 
function getMinMaxXYFromDriftTable_xy(path_to_table) {
	run("Open NanoJ Table (NJT)...", "load=["+path_to_table+"]");
	Table.rename(File.getName(path_to_table), "Results");

	minmaxXYdrift = newArray(4);
	minmaxXYdrift[0] = 0;
	minmaxXYdrift[1] = 0;
	minmaxXYdrift[2] = 0;
	minmaxXYdrift[3] = 0;

	for (i = 0; i < nResults; i++) {
		xDrift = getResult("X-Drift (pixels)", i);
		yDrift = getResult("Y-Drift (pixels)", i);
		if (xDrift < minmaxXYdrift[0]) minmaxXYdrift[0] = xDrift;
		if (xDrift > minmaxXYdrift[1]) minmaxXYdrift[1] = xDrift;

		if (yDrift < minmaxXYdrift[2]) minmaxXYdrift[2] = yDrift;
		if (yDrift > minmaxXYdrift[3]) minmaxXYdrift[3] = yDrift;
	}

	close("Results");
	return minmaxXYdrift;
}

