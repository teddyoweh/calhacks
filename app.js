require("dotenv").config();
const express = require("express");
const multer = require("multer");
const path = require("path");
const xrpl = require("xrpl");
const fs = require("fs");
const axios = require("axios");
const { OpenAI } = require("openai");
const user_store = require("./user_store.json");

/*
const RippleAPI = require('ripple-lib').RippleAPI;
const private_key = 'secret_key';  
const xrpAPI = new RippleAPI({
    server: 'wss://s1.ripple.com' 
})

async function checkBalance(address) {
  await xrpAPI.connect();
  
  const info = await xrpAPI.getAccountInfo(address);
  console.log(info);
  await xrpAPI.disconnect();
}
;
xrpAPI.connect().then(() => {
    console.log('Connected to XRP Ledger');
}).catch((error) => {
    console.error('Error connecting to XRP Ledger:', error);
});
*/

const app = express();
const PORT = 3000;


/*
const generateXRPAddress = async () => {
    try {
        const wallet = xrpAPI.generateAddress();  
        return wallet;
    } catch (error) {
        console.error('Error generating XRP address:', error);
        return null;
    }
};
const my_wallet = xrpAPI.generateAddress();
*/

const storage = multer.diskStorage({
	destination: (req, file, cb) => {
		cb(null, "public/models"); 
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

app.use(express.static("public"));

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

app.get("/api/card/:cardKey", (req, res) => {
	const cardKey = req.params.cardKey; // Retrieve card key from the route parameter

  console.log("Retrieving card: ", cardKey)

	if (!cardKey) {
		return res.status(400).json({ message: "Missing cardKey parameter" });
	}

	 
		let cardData = [];

    try {
 
        const cardData = require("./cardData.json"); 

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

        console.log("Recieved Post request");
        if (!req.file) {
            console.log("No file!")
            return res.status(400).json({ message: "No file uploaded" });
        }

        const { name,userid } = req.body;
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

        console.log(cardData.toString)
        let suffix = cardData.toString().length;
        newCardName = `${name}_${suffix}`

        const newCard = {
            cardName: name,
            modelPath:`models/${filePath}`,
            moveset:movesetParse,
        }


        
        cardData[newCardName] = newCard;

        console.log("Adding new card to cardData.json: ", newCard);

        
        fs.writeFileSync("cardData.json", JSON.stringify(cardData, null, 2));

        /*
        const xrpAddress = user_store[userid].xrpAddress ; 
        const xrpAmount = '10'; 
        const payment = {
            source: {
                address:my_wallet, 
                maxAmount: {
                    value: xrpAmount,
                    currency: 'XRP'
                }
            },
            destination: {
                address: xrpAddress,
                amount: {
                    value: xrpAmount,
                    currency: 'XRP'
                }
            }
        };

     
        const preparedPayment = await xrpAPI.preparePayment(my_wallet, payment);
        const signedPayment = xrpAPI.sign(preparedPayment, private_key); 
        const result = await xrpAPI.submit(signedPayment.signedTransaction);
        console.log('XRP Transaction Result:', result);
        */
        console.log("Write successful")


 
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
app.post('/api/create-address', async (req, res) => {
    try {
        const { userId } = req.body;  

        

        const xrpAddress = await generateXRPAddress();
        const username = user_store[userId].username;
        user_store[userId]={}
        user_store[userId].xrpAddress = xrpAddress;

        if (!xrpAddress) {
            return res.status(500).json({ message: 'Error generating XRP address' });
        }
 

        res.status(201).json({
            message: 'XRP address created and assigned to the user',
            userId,
            username,
            xrpAddress,
        });
    } catch (error) {
        console.error('Error creating and assigning XRP address:', error);
        res.status(500).json({ message: 'Error creating and assigning XRP address' });
    }
});

app.listen(PORT, () => {
	console.log(`Server started on port ${PORT}`);
});
