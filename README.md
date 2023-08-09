# DS 453 Project: Data dashboard developer

Tags: project

# 1. Intro

Our company would design a data dashboard for Boston University (BU) community to understand, measure, and improve sustainability. The dashboard would display weekly aggregation data from sensors which capture energy consumption in CDS building. Our easy-to-read and easy-to-us dashboard would provide other parameters of data, data in diagram, insights of data, and recommendations for BU students and faculties. Meanwhile, we would ensure confidentiality, integrity, and availability of the raw data. To briefly illustrate, all the sensors would post their aggregation data to Ethereum blockchain, which is based on Ethereum, and we would use technology of ZK proof to prove the correctness of data while ensuring the data confidentiality. 

# 2. Structure

<img scr="structure.png">

# 3. Data Access and Computation

## 3.1 Ethereum blockchain

We would use Ethereum as the blockchain platform. The reason why we do not use Bitcoin is that the smart contract of Bitcoin is not turing complete, meaning it may not solve any computational problem given to this complexity. Thus, since Ethereum’s smart contract is turing complete and Ethereum has a great ecosystem and developer community, we would choose Ethereum to design smart contracts for data proving.

## 3.2 Access data sources

The aggregation data of each sensor would be stored using smart contract, instead of posting transaction.
The first reason is that using smart contract to store data would be efficient and fast to retrieve. To illustrate, when data is stored in a smart contract, it is written to the blockchain, making it accessible to anyone with an internet connection, as Ethereum blockchain is public, transparent, and decentralized. With certain public function, we are able to access the aggregation data of each sensor by using block explorers. As for transactions, data stored in these are not directly accessible on-chain in the same way as data stored in a smart contract. It is because the data is not directly queryable or accessible on-chain through smart contract functions. Instead, we have to use off-chain tools to acquire data. 

Other important reason is that storing data in smart contracts would provide long-term persistence, because data is stored in Ethereum blockchain and thus can be accessed as long as the contract exists. As for data stored in transaction, they are not directly accessible, because when the transaction becomes part of the blockchain's history, data, as mentioned above, are not directly queryable.

One thing should be mentioned is that the cost of storing data in smart contracts is more expensive than in transactions. However, since in the scenario of data dashboard, the data stored would be frequently accessed, and accessing data from a smart contract is free, it would be cost-efficient and more suitable to use smart contracts, rather than transactions.

Therefore, when we we can filter the aggregation data of sensors by their category, floor, and area through accessing their own smart contract. 

## 3.3 Confidentiality of daily data

It should be noted that data in transaction in blockchain can be considered as public, because anyone with access to the smart contract can view the transactions. Thus, sensor manufacturer implement a pair of public key and secret key in each sensor. And each sensor would use **public key cryptography** to do the encryption. 

Because both consulting company and our company would need to access the raw daily data, we cannot encrypt the data using one of the two’s public key. In that way, the other party would not be able to acquire the data. Thus, in order to let two parties have access to the data, the sensor make a copy of signed data for each recipient. To illustrate, the sensor would first sign the hashed data with their own private key, creating a unique digital signature. Due to the property of digital signature, it is difficult to find the signature corresponding to the data, while, given a public key, it is easy to check whether the signature corresponding to the data is correct. Then, the sensor would make a copy of the signed data and encrypt each copy with one recipient's public key and send it along. The recipients can use their private keys to decrypt the data. 

Thus, as only the blockchain consulting firm and us can decrypt the data, the manufacturer would be confident to upload encrypted data to blockchain without worries of data leaking. The sensor manufacturer would create a smart contract using Solidity to achieve the confidentiality:

1. Establish clear identifiers for the two parties, i.e. the consulting firm and us, involved in the smart contract create a smart contract.
2. Use `modifier` feature of Solidity to create a modifier `OnlyTwoParties` that restricts only the two parties to access the data.
3. Apply the modifier `OnlyTwoParties` to the smart contract function `GetData` that allows we to acquire the daily data.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contract {
		// we would use key-value pair to store data pair of data and encrypted data
		mapping(string => uint) public store;
    address private consulting;
    address private dashboard;

    constructor(address _dashboard, address _consulting) {
        dashboard = _dashboard;
				consulting = _consulting;
    }

    modifier OnlyTwoParties() {
        require(msg.sender == dashboard msg.sender == consulting, 
				"Access restricted to the two parties");
        _;
    }

    function GetData(string memory date, string pk) public OnlyOneParties {
		    // send encrypted data to the receiver
				// the receiver decrypts data with its own secret key
				data = decrypt(store[date], (pk, zk))	// zk: the zk-proof of the data
				return (data, zk);
		}
}
```

## 3.4 Data computation

As a dashboard developer, the daily data of each sensor, from our perspective, is still raw data. In order to provide user with more intuitive insights and trends of the data, we would provide filters in our dashboard that allows users to sort out data based on floor, category, area, show data aggregated in week, or quarter, and make comparison on the same filter with other floor. Meanwhile, we would also provide some common math parameters, like mean, median, distribution of the aggregation data.

However, those precesses require a huge amount of computation. Thus, instead of doing the computation ourselves, we would collaborate with n (n>3) several trustful network servers, , and let them do the computation using secure MPC using a (3, n)-threshold secret sharing scheme using Shamir Secret Sharing.

To illustrate, this approach of secure MPC, which allows multiple parties to compute a function on their private inputs, without revealing those inputs to each other. And this technique achieves data confidentiality, integrity, and availability. 

- For confidentiality, VSS divides the secret into shares, and each is distributed to a different participant. In this way, the share reveals nothing about the secret data unless all three servers are involved in the reconstruction.
- For integrity, VSS with commitments ensures that each server can verify that the shares they receive are consistent and valid, without revealing the actual data. If a malicious server provides inconsistent shares, the other servers are able to detect that and would abort MPC, which helps to maintain data integrity by ensuring that the secret sharing is performed correctly and that the servers can trust the shares received.
- For availability, in (3, 3)-threshold secret sharing scheme, availability is more challenging to achieve, because all three servers must participate in the reconstruction to recover the secret data. If one server fails or goes offline, the secret cannot be reconstructed. However, the servers we collaborate with is trustful and their clouds are stable and thus error can hardly occur. Therefore, we can overlook this issue of server failure.

## 3.5 Confidence from users

All the faculties, students, and users of the data dashboard would be the light nodes. Because it has low bandwidth and storage requirements, users can access the dashboard through their devices, like laptops and phones. One concern that users would have is that since light nodes only store block headers that contain summary information about the contents of the blocks, they could be fooled by fake or invalid data. Thus, our solution to ensuring the correctness would be zero-knowledge proof. In this case, we would use zk-SNARK proof. The zk-proof would have two parts: 

1. Prove that the raw daily data is correct and comes from corresponding sensor
2. Prove that the computation of cloud servers is correct

For the first part, we assume that the sensor manufacturer has done that for us as they generate a zero-knowledge proof for the daily data and link the proof to data when storing them into the smart contract.

For the second part, we would create another zk-SNARK proof with the list of tuple of data and the zero-knowledge proof associated with these data as input. When we randomly partition each data into three random shares, we generate zk-proof to show the shares are indeed added up to be the value of the data and link the zk-proof to the data. 

Then, each servers would perform (3, n)-threshold MPC using Shamir Secret Sharing. Each servers want to prove the statement that the calculated result using shares they have is correct. To prove that, each server would first check whether each share is correct by checking the linked zk-proof. Then, each server would do the computation and return a zk-proof to show their computation on their shares is correct. At the end of the MPC, we would get three zk-proofs on shares from each sever. Then, we can combine the three to get the zk-proof of the correctness of the desired parameter.

# 4. Dashboard Design

The dashboard design prototype is shown below.

For the frontend of our dashboard, we would mainly use JavaScript to create all the UI and dynamic and interactive features.

<img src="interface.png">

# 5. Insights and Recommendation

- Based on the data analysis, identify areas where waste reduction or sustainability improvements can be made
- Compare the performance of different areas within the campus to identify best practices and areas for improvement
- Based on the analysis, develop realistic specific targeted recommendations for waste reduction and sustainability improvement
- Monitor the implementation and effectiveness of the recommendations over time
- Review and update the insights and recommendations on a weekly basis to ensure they remain relevant and effective

# 6. Quotation

[https://www.alchemy.com/overviews/light-node](https://www.alchemy.com/overviews/light-node)

[https://chain.link/education-hub/off-chain-data](https://chain.link/education-hub/off-chain-data)

[https://medium.com/amberdata/the-definitive-guide-to-successfully-integrating-off-chain-data-into-your-ethereum-smart-contract-ec81d95ea441](https://medium.com/amberdata/the-definitive-guide-to-successfully-integrating-off-chain-data-into-your-ethereum-smart-contract-ec81d95ea441)

[https://ethereum.org/en/developers/docs/smart-contracts/#:~:text=A "smart contract" is simply,be the target of transactions](https://ethereum.org/en/developers/docs/smart-contracts/#:~:text=A%20%22smart%20contract%22%20is%20simply,be%20the%20target%20of%20transactions).

[https://www.freecodecamp.org/news/what-are-solidity-modifiers/#:~:text=Modifiers in Solidity are special,to rewrite the entire function](https://www.freecodecamp.org/news/what-are-solidity-modifiers/#:~:text=Modifiers%20in%20Solidity%20are%20special,to%20rewrite%20the%20entire%20function).

[https://www.tutorialspoint.com/solidity/solidity_function_modifiers.htm](https://www.tutorialspoint.com/solidity/solidity_function_modifiers.htm)

[https://medium.com/@keylesstech/a-beginners-guide-to-shamir-s-secret-sharing-e864efbf3648](https://medium.com/@keylesstech/a-beginners-guide-to-shamir-s-secret-sharing-e864efbf3648)

[https://crypto.stackexchange.com/questions/66037/what-is-the-role-of-a-circuit-in-zk-snarks](https://crypto.stackexchange.com/questions/66037/what-is-the-role-of-a-circuit-in-zk-snarks)

[https://media.consensys.net/introduction-to-zksnarks-with-examples-3283b554fc3b](https://media.consensys.net/introduction-to-zksnarks-with-examples-3283b554fc3b)

[https://www.tutorialspoint.com/solidity/solidity_arrays.htm](https://www.tutorialspoint.com/solidity/solidity_arrays.htm)

[https://medium.com/coinmonks/zokrates-zksnarks-on-ethereum-made-easy-8022300f8ba6](https://medium.com/coinmonks/zokrates-zksnarks-on-ethereum-made-easy-8022300f8ba6)

[https://www.youtube.com/watch?v=RMUj3eFMA24&ab_channel=BillBuchananOBE](https://www.youtube.com/watch?v=RMUj3eFMA24&ab_channel=BillBuchananOBE)

[https://zokrates.github.io](https://zokrates.github.io/gettingstarted.html)

[https://www.cryptomathic.com/news-events/blog/symmetric-key-encryption-why-where-and-how-its-used-in-banking](https://www.cryptomathic.com/news-events/blog/symmetric-key-encryption-why-where-and-how-its-used-in-banking)

[https://www.geeksforgeeks.org/implementing-shamirs-secret-sharing-scheme-in-python/#](https://www.geeksforgeeks.org/implementing-shamirs-secret-sharing-scheme-in-python/#)
