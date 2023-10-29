require("dotenv").config();
const express = require("express");
const multer = require("multer");
const path = require("path");
const xrpl = require("xrpl");
const fs = require("fs");
const axios = require("axios");
const { OpenAI } = require("openai");
const user_store = require("./user_store.json");

const client = new xrpl.Client("wss://s.altnet.rippletest.net:51233");


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


const mintNFT = async (senderWallet, receiverWallet, cardData) => {
	try {
		// Define the XRP amount to send (adjust as needed)
		const xrpAmount = "100"; // The amount of XRP to send

		// Define the XRPL client
		const client = new xrpl.Client("wss://s.altnet.rippletest.net:51233");

		// Connect to the XRPL ledger
		await client.connect();

		// Create a Payment transaction to mint the NFT
		const paymentTx = xrpl.Transaction.makeCreatePaymentTx({
			from: senderWallet.classicAddress,
			to: receiverWallet.classicAddress,
			amount: xrpAmount,
			cardData: cardData, // Replace with the actual field you want to include
			// You can add more custom fields here based on the structure of cardData
		});

		// Sign the Payment transaction
		const signedPaymentTx = xrpl.Transaction.sign(
			paymentTx,
			senderWallet.secret,
			{ fee: "12", maxLedgerVersionOffset: 5 }
		);

		// Submit the Payment transaction to the XRPL
		const submission = await xrpl.Transaction.submit(signedPaymentTx);

		// Check if the submission was successful
		if (submission.resultCode === "tesSUCCESS") {
			console.log("NFT minted successfully");
			return true;
		} else {
			console.error("NFT minting failed:", submission.resultMessage);
			return false;
		}
	} catch (error) {
		console.error("Error minting NFT:", error);
		return false;
	} finally {
		// Disconnect from the XRPL ledger
		if (client && client.isConnected()) {
			await client.disconnect();
		}
	}
};


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
		console.log("No file!");
		return res.status(400).json({ message: "No file uploaded" });
	}

	const { name, userid } = req.body;
	const filePath = req.file.filename;

	console.log("File uploaded: ", filePath);

	let cardData = [];
	try {
		console.log("Reading cardData.json");
		cardData = JSON.parse(fs.readFileSync("cardData.json"));
	} catch (err) {
		console.error("Error reading cardData.json:", err);

		res.status(500).json({ message: "Error uploading reading file" });
	}

	console.log(cardData);

	const moveset = await generateMoveset(name);

	console.log(moveset);

	movesetParse = JSON.parse(moveset);

	console.log(movesetParse);

	const formattedMovesetString = JSON.stringify(moveset, null, 2);

	console.log(formattedMovesetString);

	console.log(cardData.toString);

	let suffix = Object.keys(cardData).length;
	newCardName = `${name}_${suffix}`;

	const newCard = {
		cardName: name,
		modelPath: `models/${filePath}`,
		moveset: movesetParse,
	};

	cardData[newCardName] = newCard;

	console.log("Adding new card to cardData.json: ", newCard);

	fs.writeFileSync("cardData.json", JSON.stringify(cardData, null, 2));


  /*
	// Create a client to connect to the XRPL test network
	const client = new xrpl.Client("wss://s.altnet.rippletest.net:51233");

	// Creating two wallets for sending money between
	const wallet1 = generate_faucet_wallet(client, (debug = true));
	const wallet2 = generate_faucet_wallet(client, (debug = true));

	// Both balances should be zero since nothing has been sent yet
	console.log("Balances of wallets before Payment tx");
	console.log(get_balance(wallet1.classic_address, client));
	console.log(get_balance(wallet2.classic_address, client));

	// Create a Payment transaction
	const paymentTx = Payment({
		account: wallet1.classic_address,
		amount: "100", // The amount of XRP to send
		destination: wallet2.classic_address,
	});

	// Sign and autofill the transaction
	const signedPaymentTx = safe_sign_and_autofill_transaction(
		paymentTx,
		wallet1,
		client
	);

	// Submits transaction and waits for response (validated or rejected)
	const paymentResponse = send_reliable_submission(signedPaymentTx, client);
	console.log("Transaction was submitted");

	// Call the mintNFT function to mint an NFT and pass the sender wallet, receiver wallet, and any card data
	const mintingResult = await mintNFT(wallet1, wallet2, cardData);

	if (mintingResult) {
		console.log("NFT minted successfully");
	} else {
		console.error("NFT minting failed");
	}

	// Create a Transaction request to see transaction
	const txResponse = client.request(
		Tx({ transaction: paymentResponse.result.hash })
	);

	// Check validated field on the transaction
	console.log("Validated:", txResponse.result.validated);

	// Check balances after XRP was sent from wallet1 to wallet2
	console.log("Balances of wallets after Payment tx:");
	console.log(get_balance(wallet1.classic_address, client));
	console.log(get_balance(wallet2.classic_address, client));

  */
	console.log("Write successful");

	res.status(200).json({
		message: "File uploaded and data written successfully",
	});
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
