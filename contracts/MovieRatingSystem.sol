// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "./MovieRatingToken.sol";
import "./Certificate.sol";

contract MovieRatingSystem {
    struct User {
        address userAddress;
        bool isContentCreator;
        uint256 tokenBalance;
        uint256 rep;
        bool validated;
    }

    struct Movie {
        address contentCreator;
        string movieName;
        uint256 totalRating;
        uint256 ratingCount;
        uint256 avgRating;
    }

    struct Rating {
        address user;
        uint256 rating;
    }

    struct Validator {
        address validatorAddress;
        bool registered;
    }

    mapping(address => User) public users;
    mapping(address => Validator) public validators;
    MovieRatingToken public tokenContract;
    mapping(address => Movie[]) public moviesAddedByUser;
    mapping(address => Rating[][]) public moviesRatedByUser;
    mapping(address => mapping(address => bool)) public likedReviews;
    Certificate public certificateContract;
    uint256 public userCount;
    address[] public userAddresses;
    event UserSignUp(address indexed userAddress, bool isContentCreator);
    event MovieAdded(address indexed contentCreator, string movieName);
    event MovieReviewed(address indexed user, address indexed contentCreator, string movieName, string review);
    event MovieRated(address indexed user, address indexed contentCreator, string movieName, uint256 rating);
    event ReviewLiked(address indexed reviewer, address indexed contentCreator);
    event ValidatorSignUp(address indexed validator);

    constructor(address _tokenContract, address _certificateContract) {
        tokenContract = MovieRatingToken(_tokenContract);
        certificateContract = Certificate(_certificateContract);
        userCount = 0;
    }

    function signUp(bool _isContentCreator) external {
    require(users[msg.sender].userAddress == address(0), "User already signed up");

    uint256 tokenCost = 0; // Cost of signup, assuming 1 token

    require(tokenContract.balanceOf(msg.sender) >= tokenCost, "Insufficient token balance");

    require(tokenContract.transferFrom(msg.sender, address(this), tokenCost), "Token transfer failed");

    if (validators[msg.sender].validatorAddress != address(0)) {
        revert("Validators cannot sign up as users");
    }

    users[msg.sender] = User(msg.sender, _isContentCreator, 100, 0, false);
    userCount++;
    userAddresses.push(msg.sender);
    emit UserSignUp(msg.sender, _isContentCreator);
    
    }


    function replenishTokens() external {
    address[] memory userAddresses = getAllUserAddresses();
    
    for (uint256 i = 0; i < userAddresses.length; i++) {
        address userAddress = userAddresses[i];
        User storage user = users[userAddress];

        require(user.userAddress != address(0), "User not found");

        uint256 tokenCost = 0; // Cost of token replenishment, assuming 100 tokens

        require(tokenContract.balanceOf(address(this)) >= tokenCost, "Insufficient token supply");

        require(tokenContract.transfer(userAddress, tokenCost), "Token transfer failed");

        user.tokenBalance = 100;
    }
}


    function getAddressAtIndex(mapping(address => User) storage _mapping, uint256 _index) internal view returns (address) {
    address[] memory keys = new address[](userCount);
    uint256 counter = 0;
    for (uint256 i = 0; i < userCount; i++) {
        address userAddress = getAddressAtIndex(_mapping, i);
        if (_mapping[userAddress].userAddress != address(0)) {
            if (counter == _index) {
                return userAddress;
            }
            counter++;
        }
    }
    revert("Index out of bounds");
}


    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }
    function addMovie(string memory _movieName) external {
        User storage contentCreator = users[msg.sender];
        require(contentCreator.userAddress != address(0), "Content creator not signed up");
        require(contentCreator.isContentCreator, "Unauthorized action");

        uint256 tokenCost = 1; // Cost of adding a movie, assuming 1 token

        require(contentCreator.tokenBalance >= tokenCost, "Insufficient token balance");

        // Perform the action of adding a movie
        moviesAddedByUser[msg.sender].push(Movie(msg.sender, _movieName, 0, 0, 0));

        emit MovieAdded(msg.sender, _movieName);

        contentCreator.tokenBalance -= tokenCost;
    }

    function reviewMovie(address _contentCreator, string memory _movieName, string memory _review) external {
        User storage user = users[msg.sender];
        require(user.userAddress != address(0), "User not signed up");

        uint256 tokenCost = 1; // Cost of reviewing a movie, assuming 1 token

        require(user.tokenBalance >= tokenCost, "Insufficient token balance");

        // Perform the action of reviewing a movie
        emit MovieReviewed(msg.sender, _contentCreator, _movieName, _review);

        user.tokenBalance -= tokenCost;
    }

    function rateMovie(address _contentCreator, string memory _movieName, uint256 _rating) external {
        User storage user = users[msg.sender];
        require(user.userAddress != address(0), "User not signed up");

        uint256 tokenCost = 1; // Cost of rating a movie, assuming 1 token

        require(user.tokenBalance >= tokenCost, "Insufficient token balance");

        // Perform the action of rating a movie
        emit MovieRated(msg.sender, _contentCreator, _movieName, _rating);

        Movie[] storage movies = moviesAddedByUser[_contentCreator];
        uint256 movieIndex = getMovieIndex(movies, _movieName);

        require(movieIndex < movies.length, "Movie not found");

        Movie storage movie = movies[movieIndex];

        // Update the total rating and rating count of the movie
        movie.totalRating += _rating;
        movie.ratingCount += 1;
        movie.avgRating = movie.totalRating / movie.ratingCount;

        user.tokenBalance -= tokenCost;
    }

    function likeReview(address _contentCreator, address _reviewer) external {
        User storage contentCreator = users[_contentCreator];
        require(contentCreator.userAddress != address(0), "Content creator not signed up");
        require(contentCreator.isContentCreator, "Unauthorized action");

        require(users[_reviewer].userAddress != address(0), "Reviewer not signed up");

        require(!likedReviews[_contentCreator][_reviewer], "Already liked the review");

        contentCreator.rep += 50;
        likedReviews[_contentCreator][_reviewer] = true;

        emit ReviewLiked(_reviewer, _contentCreator);
    }

    function getMovieIndex(Movie[] storage _movies, string memory _movieName) internal view returns (uint256) {
        bytes32 movieHash = keccak256(abi.encodePacked(_movieName));
        for (uint256 i = 0; i < _movies.length; i++) {
            bytes32 existingMovieHash = keccak256(abi.encodePacked(_movies[i].movieName));
            if (movieHash == existingMovieHash) {
                return i;
            }
        }
        return _movies.length;
    }

    function uploadCertificate(string memory _certificateHash) external {
        certificateContract.uploadCertificate(_certificateHash);
    }

    function validateCertificate(address _owner, bool _status) external {
        certificateContract.validateCertificate(_owner);
        User storage user = users[_owner];
        if (!user.isContentCreator || _status) {
            user.validated = _status;
        }
        user.rep += 100;
    }

    function validatorSignUp() external {
        require(users[msg.sender].userAddress == address(0), "Validator cannot be a user");
        require(!users[msg.sender].isContentCreator, "Validator cannot be a content creator");
        require(validators[msg.sender].validatorAddress == address(0), "Validator already signed up");

        validators[msg.sender] = Validator(msg.sender, true);

        emit ValidatorSignUp(msg.sender);
    }
}