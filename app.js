require("dotenv").config();
const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const axios = require("axios");
const { OpenAI } = require("openai");


const app = express();
const PORT = 3000;


const storage = multer.diskStorage({
	destination: (req, file, cb) => {
		cb(null, "models"); 
	},
	filename: (req, file, cb) => {
		const extname = path.extname(file.originalname);
		cb(null, file.fieldname + extname);
	},
});

const upload = multer({ storage: storage });


const apiKey = process.env.OPENAI_KEY; 


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

        
        let cardData = [];
        try {
            cardData = JSON.parse(fs.readFileSync("cardData.json"));
        } catch (err) {
            
        }

        const moveset = await generateMoveset(name);

        const newCard = { name, filePath, moveset };

        cardData.push(newCard);

        
        fs.writeFileSync("cardData.json", JSON.stringify(cardData));

        res.status(201).json({
            message: "File uploaded successfully",
            fileName: req.file.filename,
            description: newCard.description,
        });
    } catch (error) {
        res.status(500).json({ message: "Error uploading file" });
    }
});


async function generateMoveset(name) {
	try {

    promptToSend = "Generate a moveset for a card game character consisting of two moves based on the name of the object/character. Each move should deal between 10 - 25 damage points. Try and base the damage values based on how dangerous or unique the object is. The movedescription should be a one line phrase. Return this moveset in the following format: { moveOne{name: moveName,damage: #, moveDescription: insert a relevant description}, moveTwo{name: moveName,damage: #, moveDescription: insert a relevant description} } Name: " + name
		const response = await openai.createChatCompletion({
			model: "gpt-3.5-turbo",
			messages: [
				{
					role: "system",
					content: "You are a system that generates movesets for a card game character.",
				},
				{
					role: "user",
					content: promptToSend,
				},
			],
			max_tokens: 500,
			temperature: 0.9,
		});

    return response.data.choices[0].message.content;
	} catch (error) {
		console.error("Error generating description:", error);
		return "Description not available";
	}
}

app.listen(PORT, () => {
	console.log(`Server started on port ${PORT}`);
});
