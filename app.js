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
const { generate_faucet_wallet } = require("xrpl-wallet");
const { Payment } = require("xrpl-models-transactions");
const {
	safe_sign_and_autofill_transaction,
	send_reliable_submission,
} = require("xrpl-transaction");
const { IssuedCurrencyAmount } = require("xrpl-models");
const { Payment } = require("xrpl-models-transactions");
const {
	safe_sign_and_autofill_transaction,
	send_reliable_submission,
} = require("xrpl-transaction");

*/
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


/*async function mintNFT(senderWallet, receiverWallet, cardData) {
    // Create a Payment transaction with an IssuedCurrencyAmount representing the NFT
    const nftPaymentTx = Payment({
        account: senderWallet.classic_address,
        amount: IssuedCurrencyAmount.from_json({
            currency: 'NFT',
            issuer: senderWallet.classic_address,
            value: '1'
        }),
        destination: receiverWallet.classic_address,
    });

    // Sign and autofill the transaction
    const signedNftPaymentTx = await safe_sign_and_autofill_transaction(nftPaymentTx, senderWallet);

    // Submit the transaction and wait for response (validated or rejected)
    const nftPaymentResponse = await send_reliable_submission(signedNftPaymentTx);

    // Check if the NFT payment was successful
    if (nftPaymentResponse.result.engine_result === 'tesSUCCESS') {
        console.log("NFT payment successful");

        // Add the NFT to the receiver's card data
        const receiverCardData = JSON.parse(JSON.stringify(cardData));
        receiverCardData[receiverWallet.classic_address] = {
            nft: true,
            sender: senderWallet.classic_address,
            timestamp: Date.now()
        };

        // Write the updated card data to file
        fs.writeFileSync("cardData.json", JSON.stringify(receiverCardData, null, 2));

        return true;
    } else {
        console.error("NFT payment failed");
        return false;
    }
  }

*/
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



app.post(
	"/api/create",
	upload.fields([{ name: "image" }, { name: "model" }]),
	async (req, res) => {
		console.log("Recieved Post request");

    console.log(req.files);

    const imageFile = req.files["image"];
	  const modelFile = req.files["model"];

    if (!imageFile || !modelFile) {
		console.log("One or both files missing!");
		return res.status(400).json({ message: "One or both files missing" });
	}
		const { name, userid } = req.body;

    
    const imageFilePath = imageFile["path"];
	  const modelFilePath = modelFile["path"];

		console.log("Image file uploaded: ", imageFilePath);
		console.log("3D model file uploaded: ", modelFilePath);

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
			modelPath: `models/${modelFilePath}`,
      imagePath: `models/${imageFilePath}`,
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

		// Sign and autofill the transaction
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
	}
);


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
