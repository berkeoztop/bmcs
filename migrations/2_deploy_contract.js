// File: 2_deploy_contracts.js
const MovieRatingToken = artifacts.require("MovieRatingToken");
const MovieRatingSystem = artifacts.require("MovieRatingSystem");
const Certificate = artifacts.require("Certificate");

module.exports = function (deployer) {
  // Deploy MovieRatingToken contract
  deployer.deploy(Certificate);
   deployer.deploy(MovieRatingToken, "MovieRatingToken", "MRT").then(function()
   {
    return deployer.deploy(MovieRatingSystem, MovieRatingToken.address, Certificate.address)
   })
   
};