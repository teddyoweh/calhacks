// const axios = require("axios");

// // Define the URL of your server's API
// const serverApiUrl = "http://localhost:3000/api/card"; // Adjust the URL accordingly

// // Define the card name you want to search for
// const cardName = "Pumpkin"; // Change to the desired card name

// // Make an HTTP GET request to find the card by name
// axios
// 	.get(`${serverApiUrl}?cardName=${cardName}`)
// 	.then((response) => {
// 		const card = response.data;
// 		if (card) {
// 			console.log("Card found:", card);
// 		} else {
// 			console.log(`Card with name "${cardName}" not found.`);
// 		}
// 	})
// 	.catch((error) => {
// 		console.error("Error:", error.message);
// 	});
