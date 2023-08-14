// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract VerifySignature {
    function verify(address _signer, string memory _message, bytes memory _sig) 
        external pure returns (bool) {
            bytes32 messageHash = getMessageHash(_message);
            bytes32 ethSignedMessgaeHash = getEthSignedMessageHash(messageHash);
            return recover(ethSignedMessgaeHash, _sig) == _signer;
        }
    function getMessageHash(string memory _message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message));
    }
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _messageHash
            ));
    }
    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public pure returns (address) 
    {
            (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
            return ecrecover(_ethSignedMessageHash, v, s, r);
    }
    function _split(bytes memory _sig) internal pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(_sig.length==65, "invalid signature length");
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0,mload(add(_sig, 96)))
        }
    } 
}

contract ZKProof {
    function zk1(VerifySignature _verifySignature, string memory _message, bytes memory _sig, uint _data, uint[] memory _shares) public view {
        /*
            This zk-proof is to show:
                1) the data is correct and comes from the corresponding sensor 
                2) the shares we generate can indeed add up 
                to be the value of the data
            _message: message from the sensor
            _sig: sencor's signature
            _data: the stored data of sensor
            _shares: the three shares we randomly generate
        */  
        require(_verifySignature.verify(msg.sender, _message, _sig), "invalid signature");
        uint sum = 0;
        for(uint i=0; i<_shares.length; i++) {
            sum += _shares[i];
        }
        require(sum == _data, "incorrect value");
    }
}
