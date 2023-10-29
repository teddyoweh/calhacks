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


const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const apiUrl = 'http://localhost:3000/api/create'; // Replace with your API endpoint

const uploadImage = async () => {
  try {
    const formData = new FormData();
    formData.append('model', fs.createReadStream('test-image.jpg')); // Replace 'test-image.jpg' with your image file name
    formData.append('name', 'Scientist'); // Replace 'YourName' with the desired name

    const response = await axios.post(apiUrl, formData, {
      headers: {
        ...formData.getHeaders(),
      },
    });

    console.log(response.data);
  } catch (error) {
    console.error('Error uploading file:', error.message);
  }
};

uploadImage();
