import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import axios from "axios";
import OpenAI from "openai"; // Import OpenAI module as specified

const app = express();
const PORT = 3000;

// Configure multer to store uploaded files in the "models" directory
const storage = multer.diskStorage({
	destination: (req, file, cb) => {
		cb(null, "models"); // Store files in the "models" directory
	},
	filename: (req, file, cb) => {
		const extname = path.extname(file.originalname);
		const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
		cb(null, file.fieldname + "-" + uniqueSuffix + extname);
	},
});

const upload = multer({ storage: storage });

// Your OpenAI GPT-3.5 Turbo API key
const apiKey = "YOUR_OPENAI_API_KEY"; // Replace with your API key

// Create an OpenAI client
const openai = new OpenAI({
	apiKey,
});

app.post("/api/create", upload.single("model"), async (req, res) => {
	try {
		if (!req.file) {
			return res.status(400).json({ message: "No file uploaded" });
		}

		const { name } = req.body;
		const filePath = req.file.filename;

		// Create an object with the card name and file path
		const cardData = { name, filePath };

		// Generate a description based on the name using GPT-3.5 Turbo
		const moveset = await generateMoveset(name);

		// Add the description to the cardData object
		cardData.moveset = moveset;

		// Write the card data to a JSON file
		fs.writeFileSync("cardData.json", JSON.stringify(cardData));

		res.status(201).json({
			message: "File uploaded successfully",
			fileName: req.file.filename,
			description,
		});
	} catch (error) {
		res.status(500).json({ message: "Error uploading file" });
	}
});

// Function to generate a moveset using GPT-3.5 Turbo
async function generateMoveset(name) {
	try {
		const response = await openai.createChatCompletion({
			model: "gpt-3.5-turbo",
			messages: [
				{
					role: "system",
					content: "You are a system that generates movesets for a card game character.",
				},
				{
					role: "user",
					content: name,
				},
			],
			max_tokens: 500,
			temperature: 0.9,
		});
		console.log(response.data.choices[0].message.content);

    return response.data.choices[0].message.content;
	} catch (error) {
		console.error("Error generating description:", error);
		return "Description not available";
	}
}

app.listen(PORT, () => {
	console.log(`Server started on port ${PORT}`);
});
