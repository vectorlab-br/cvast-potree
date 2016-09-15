var sceneProperties = {
	path: "../resources/pointclouds/paris_nhm_whale_1/cloud.js",
	cameraPosition: null, 		// other options: cameraPosition: [10,10,10],
	cameraTarget: null, 		// other options: cameraTarget: [0,0,0],
	fov: 60, 					// field of view in degrees,
	sizeType: "Adaptive",	// other options: "Fixed", "Attenuated"
	quality: "Circles", 			// other options: "Circles", "Interpolation", "Splats"
	material: "RGB", 		// other options: "Height", "Intensity", "Classification"
	pointLimit: 4,				// max number of points in millions
	pointSize: 0.1,				// 
	navigation: "Orbit",		// other options: "Orbit", "Flight"
	useEDL: false,				
};
