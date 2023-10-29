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
        cb(null, file.originalname); 
    }
});

const upload = multer({ storage: storage });


const apiKey = process.env.OPENAI_KEY; 


const openai = new OpenAI({
	apiKey,
});

app.get("/", (req, res) => {
	res.send("Hello World!");
});

app.get("/api/get-cards", (req, res) => {
    try {
        const cardData = JSON.parse(fs.readFileSync("cardData.json"));
        res.status(200).json(cardData);
    } catch (err) {
        res.status(500).json({ message: "Error reading card data" });
    }
});

app.get("/api/card", (req, res) => {
    const cardName = req.query.cardName;

    if (!cardName) {
        return res.status(400).json({ message: "Missing cardName parameter" });
    }

    try {
        const cardData = require("./cardData.json"); // Load the JSON file

        // Check if the cardName exists in the cardData object
        if (cardData.hasOwnProperty(cardName)) {
            const card = cardData[cardName];
            res.status(200).json(card);
        } else {
            res.status(404).json({ message: "Card not found" });
        }
    } catch (err) {
        res.status(500).json({ message: "Error reading card data" });
    }
});


app.post("/api/create", upload.single("model"), async (req, res) => {
    try {
        console.log("Recieved Post request");
        if (!req.file) {
            console.log("No file!")
            return res.status(400).json({ message: "No file uploaded" });
        }

        const { name } = req.body;
        const filePath = req.file.filename;

        console.log("File uploaded: ", filePath)
        
        let cardData = [];
        try {
            console.log("Reading cardData.json")
            cardData = JSON.parse(fs.readFileSync("cardData.json"));

        } catch (err) {
            console.error("Error reading cardData.json:", err);

            res.status(500).json({ message: "Error uploading reading file" });
        }

        console.log(cardData)


        const moveset = await generateMoveset(name);

        console.log(moveset);

        movesetParse = JSON.parse(moveset);

        console.log(movesetParse)

        const formattedMovesetString = JSON.stringify(moveset, null, 2);

        console.log(formattedMovesetString)


        const newCard = {
            cardName:`name_${cardData.length}`,
            modelPath:`models/${filePath}`,
            moveset:movesetParse,
        }



        cardData[name] = newCard;

        console.log("Adding new card to cardData.json: ", newCard);

        
        fs.writeFileSync("cardData.json", JSON.stringify(cardData, null, 2));

        console.log("Write successful")

        res.status(201).json({
            message: "File uploaded successfully",
            fileName: req.file.filename,
            description: newCard.description,
        });
    } catch (error) {
        console.error("Error uploading file:", error);
        res.status(500).json({ message: "Error uploading file" });
    }
});


async function generateMoveset(name) {
	try {
        console.log("Generating moveset for: ", name)

    promptToSend = "Generate a moveset for a card game character consisting of two moves based on the name of the object/character. Each move should deal between 10 - 25 damage points. Try and base the damage values based on how dangerous or unique the object is. The moveDescription should be a one line phrase. Make sure to add double quotes around each key. Return this moveset in the following JSON format: { moveOne{name: moveName,damage: #, moveDescription: insert a relevant description}, moveTwo{name: moveName,damage: #, moveDescription: insert a relevant description} } ONLY RETURN THIS JSON OBJECT. DO NOT INCLUDE ANY OTHER TEXT. Name: " + name
		const response = await openai.chat.completions.create({
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
        console.log("Generated moveset: ", response.choices[0].message.content);

    return response.choices[0].message.content;
	} catch (error) {
		console.error("Error generating description:", error);
		return "Description not available";
	}
}

app.listen(PORT, () => {
	console.log(`Server started on port ${PORT}`);
});
