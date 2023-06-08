const MovieRatingSystem = artifacts.require("MovieRatingSystem");

contract("MovieRatingSystem", (accounts) => {
  it("should sign up a user", async () => {
    const movieRatingSystem = await MovieRatingSystem.deployed();

    // Call the signUp function and assert the result
    const result = await movieRatingSystem.signUp(true, { from: accounts[0] });
    assert.equal(result.logs[0].event, "UserSignUp", "UserSignUp event should be emitted");
  });

  it("should add a movie", async () => {
    const movieRatingSystem = await MovieRatingSystem.deployed();

    // Call the addMovie function and assert the result
    const result = await movieRatingSystem.addMovie("Movie 1", { from: accounts[1] });
    assert.equal(result.logs[0].event, "MovieAdded", "MovieAdded event should be emitted");
  });

  // Add more test cases as needed
});