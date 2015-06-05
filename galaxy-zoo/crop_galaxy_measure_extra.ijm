// Kaggle Galaxy Zoo competition.
// Crops the galaxy from the rest of the image

function mean(values) {
    result = 0;
    for (i = 0; i < values.length; i++) {
        result += values[i];
    }

    result /= values.length;

    return(result);
    
}

result = ""; // Final result variable
imageName = getTitle();
baseName = substring(imageName, 0, indexOf(imageName, "."));
centerX = getWidth() / 2;
centerY = getHeight() / 2;
    
// Remove noise and subtract background
//run("Despeckle");
run("Subtract Background...", "rolling=30 separate sliding disable");
    
// Create a grayscale copy (easier to process, may apply some mask for later)
run("Duplicate...", "title=gray");
selectWindow("gray");
run("16-bit");
    
// Threshold using an automatic method and create a mask
setAutoThreshold("Otsu dark");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Options...", "iterations=2 count=1 black edm=Overwrite do=Erode");
run("Options...", "iterations=2 count=1 black edm=Overwrite do=Dilate");
    
// Set measurements
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction display redirect=None decimal=3");
    
// Analyze particles
run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing clear display add");
    
// Select the ROI closer to the center of the image. Use the results table for this
selectedROI = -1;
minDistance = 1000000;
    
// Need to get the biggest particles
sizes = newArray(roiManager("count"));
    
for (i = 0; i < roiManager("count"); i++) {
    sizes[i] = getResult("Area", i);
}
    
sizes = Array.sort(sizes);
meanArea = mean(sizes);
minArea = -1;
for (i = 0; i < sizes.length && minArea == -1; i++) {
    if (sizes[i] >= meanArea) {
        minArea = sizes[i];
    }        
}

for (i = 0; i < roiManager("count"); i++) {
    area = getResult("Area", i);
    if (area >= minArea) {
        roiX = getResult("X", i);
        roiY = getResult("Y", i);
        distance = sqrt(pow(centerX - roiX, 2) + pow(centerY - roiY, 2));
        //print(i, ":", distance);
        if (distance < minDistance) {
            minDistance = distance;
            selectedROI = i;
        }
    }
}
    
// Now select the relevant ROI, clear outside and mask it
run("Clear Results"); 
selectWindow("gray");
roiManager("select", selectedROI);
run("Clear Outside");
run("Select All");
run("Measure");
M1 = getResult("Mean", 0) + 1;
run("Options...", "iterations=20 count=1 black edm=Overwrite do=Close");
run("Measure");
M2 = getResult("Mean", 1) + 1;
result = M1/M2;
// Print to log window
print(result);