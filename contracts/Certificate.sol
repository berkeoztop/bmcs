// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract Certificate {
    struct CertificateData {
        address owner;
        string certificateHash;
        bool validated;
    }

    mapping(address => CertificateData) public certificates;

    event CertificateUploaded(address indexed owner, string certificateHash);
    event CertificateValidated(address indexed owner);

    function uploadCertificate(string memory _certificateHash) external {
        require(bytes(_certificateHash).length > 0, "Certificate hash cannot be empty");
        require(certificates[msg.sender].owner == address(0), "Certificate already uploaded");

        certificates[msg.sender] = CertificateData(msg.sender, _certificateHash, false);

        emit CertificateUploaded(msg.sender, _certificateHash);
    }

    function validateCertificate(address _owner) external {
        require(certificates[_owner].owner != address(0), "Certificate not found");
        require(!certificates[_owner].validated, "Certificate already validated");

        certificates[_owner].validated = true;

        emit CertificateValidated(_owner);
    }
}