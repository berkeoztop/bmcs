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
        uint256 validationCount;
        bool isValid;
    }

    struct Rating {
        address user;
        uint256 rating;
    }

    mapping(address => User) public users;

    MovieRatingToken public tokenContract;
    mapping(address => bool) public votedForReplenishment;
    mapping(address => Movie[]) public moviesAddedByUser;
    mapping(address => Rating[][]) public moviesRatedByUser;
    mapping(address => mapping(address => bool)) public likedReviews;
    Certificate public certificateContract;
    uint256 public userCount;
    address[] public userAddresses;
    event UserSignUp(address indexed userAddress, bool isContentCreator);
    event MovieAdded(address indexed contentCreator, string movieName);
    event MovieReviewed(
        address indexed user,
        address indexed contentCreator,
        string movieName,
        string review
    );
    event MovieRated(
        address indexed user,
        address indexed contentCreator,
        string movieName,
        uint256 rating
    );
    event ReviewLiked(address indexed reviewer, address indexed contentCreator);
    event MovieValidated(address indexed contentCreator, string movieName);
    event CertificateUploaded(address indexed owner, string certificateHash);
    uint256 public replenishmentVotes;

    constructor(address _tokenContract, address _certificateContract) {
        tokenContract = MovieRatingToken(_tokenContract);
        certificateContract = Certificate(_certificateContract);
        userCount = 0;
    }

    function signUp(bool _isContentCreator) external {
        require(
            users[msg.sender].userAddress == address(0),
            "User already signed up"
        );

        uint256 tokenCost = 0; // Cost of signup, assuming 1 token

        require(
            tokenContract.balanceOf(msg.sender) >= tokenCost,
            "Insufficient token balance"
        );

        require(
            tokenContract.transferFrom(msg.sender, address(this), tokenCost),
            "Token transfer failed"
        );

        users[msg.sender] = User(msg.sender, _isContentCreator, 100, 0, false);
        userCount++;
        userAddresses.push(msg.sender);
        emit UserSignUp(msg.sender, _isContentCreator);
    }

    function replenishTokens() internal {
        address[] memory userAddresses = getAllUserAddresses();

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            User storage user = users[userAddress];

            require(user.userAddress != address(0), "User not found");

            uint256 tokenCost = 0; // Cost of token replenishment, assuming 100 tokens

            require(
                tokenContract.balanceOf(address(this)) >= tokenCost,
                "Insufficient token supply"
            );

            require(
                tokenContract.transfer(userAddress, tokenCost),
                "Token transfer failed"
            );
            if (user.isContentCreator == true) {
                user.tokenBalance += 10;
            } else {
                user.tokenBalance = 100;
            }
        }
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            votedForReplenishment[userAddress] = false;
        }
    }

    function checkValidation(
        address _contentCreator
    ) public view returns (bool) {
        User storage contentCreator = users[_contentCreator];
        require(
            contentCreator.userAddress != address(0),
            "Content creator not signed up"
        );

        return contentCreator.rep > 1500;
    }

    function voteForReplenishment() external {
        User storage user = users[msg.sender];
        require(user.userAddress != address(0), "User not signed up");
        require(
            !votedForReplenishment[msg.sender],
            "Already voted for replenishment"
        );

        votedForReplenishment[msg.sender] = true;
        replenishmentVotes++;

        // Check if the threshold of 60% votes is reached
        if (replenishmentVotes >= (userCount * 60) / 100) {
            // Replenish tokens
            replenishTokens();
        }
    }

    function getAddressAtIndex(
        mapping(address => User) storage _mapping,
        uint256 _index
    ) internal view returns (address) {
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

    function validateMovie(
        address _contentCreator,
        string memory _movieName
    ) external {
        User storage contentCreator = users[_contentCreator];
        require(
            contentCreator.userAddress != address(0),
            "Content creator not signed up"
        );
        require(contentCreator.isContentCreator, "Unauthorized action");

        Movie[] storage movies = moviesAddedByUser[_contentCreator];
        uint256 movieIndex = getMovieIndex(movies, _movieName);
        require(movieIndex < movies.length, "Movie not found");

        Movie storage movie = movies[movieIndex];
        movie.validationCount++;

        if (!movie.isValid && movie.validationCount >= (userCount * 40) / 100) {
            movie.isValid = true;
            contentCreator.rep += 200; // Increase content creator's reputation by 200 for a valid movie
            contentCreator.tokenBalance += 50; // Reward content creator with 50 tokens for a valid movie
        }

        emit MovieValidated(_contentCreator, _movieName);
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }

    function addMovie(string memory _movieName) external {
        User storage contentCreator = users[msg.sender];
        require(
            contentCreator.userAddress != address(0),
            "Content creator not signed up"
        );
        require(contentCreator.isContentCreator, "Unauthorized action");

        uint256 tokenCost = 1; // Cost of adding a movie, assuming 1 token

        require(
            contentCreator.tokenBalance >= tokenCost,
            "Insufficient token balance"
        );

        // Perform the action of adding a movie
        moviesAddedByUser[msg.sender].push(
            Movie(msg.sender, _movieName, 0, 0, 0, 0, false)
        );

        emit MovieAdded(msg.sender, _movieName);

        contentCreator.tokenBalance -= tokenCost;
    }

    function reviewMovie(
        address _contentCreator,
        string memory _movieName,
        string memory _review
    ) external {
        User storage user = users[msg.sender];
        require(user.userAddress != address(0), "User not signed up");

        uint256 tokenCost = 1; // Cost of reviewing a movie, assuming 1 token

        require(user.tokenBalance >= tokenCost, "Insufficient token balance");

        // Perform the action of reviewing a movie
        emit MovieReviewed(msg.sender, _contentCreator, _movieName, _review);

        user.tokenBalance -= tokenCost;
    }

    function rateMovie(
        address _contentCreator,
        string memory _movieName,
        uint256 _rating
    ) external {
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
        require(
            contentCreator.userAddress != address(0),
            "Content creator not signed up"
        );
        require(contentCreator.isContentCreator, "Unauthorized action");

        User storage reviewer = users[_reviewer];
        require(reviewer.userAddress != address(0), "Reviewer not signed up");

        require(
            !likedReviews[_contentCreator][_reviewer],
            "Already liked the review"
        );

        contentCreator.rep += 50;
        likedReviews[_contentCreator][_reviewer] = true;

        // Increase reviewer's token balance by 2
        reviewer.tokenBalance += 2;

        emit ReviewLiked(_reviewer, _contentCreator);
    }

    function getMovieIndex(
        Movie[] storage _movies,
        string memory _movieName
    ) internal view returns (uint256) {
        bytes32 movieHash = keccak256(abi.encodePacked(_movieName));
        for (uint256 i = 0; i < _movies.length; i++) {
            bytes32 existingMovieHash = keccak256(
                abi.encodePacked(_movies[i].movieName)
            );
            if (movieHash == existingMovieHash) {
                return i;
            }
        }
        return _movies.length;
    }

    function uploadCertificate(string memory _certificateHash) external {
        certificateContract.uploadCertificate(_certificateHash);

        User storage contentCreator = users[msg.sender];
        require(
            contentCreator.userAddress != address(0),
            "Content creator not signed up"
        );

        contentCreator.rep += 50; // Increase content creator's reputation by 50 for uploading a certificate

        emit CertificateUploaded(msg.sender, _certificateHash);
    }
}