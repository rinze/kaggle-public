run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction limit display redirect=None decimal=3");
run("Measure"); // Measure full image
run("16-bit");
setAutoThreshold("Huang dark");
run("Measure");
