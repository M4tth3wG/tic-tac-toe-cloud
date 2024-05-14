const config = {};
config.cognito = {};

config.cognito.clientId = "iqven205cvn65dis12ucaj2f0";
config.cognito.clientSecret =
  "1n4sqhqo8b8i5u6euh95uf3aetqoh97udc66484oitdmt41d6teq";
config.cognito.loginUrl =
  "https://tic-tac-toe-adrian-cloud.auth.us-east-1.amazoncognito.com/login?client_id=iqven205cvn65dis12ucaj2f0&response_type=code&scope=email+openid+phone&redirect_uri=http%3A%2F%2Flocalhost%3A3000";
config.cognito.logoutUrl =
  "https://tictactoecloud.auth.us-east-1.amazoncognito.com/logout?client_id=iqven205cvn65dis12ucaj2f0&logout_uri=http%3A%2F%2Flocalhost%3A3000";
config.cognito.tokenEndpoint =
  "https://tic-tac-toe-adrian-cloud.auth.us-east-1.amazoncognito.com/oauth2/token";
config.cognito.redirectUri = "http://localhost:3000";
config.cognito.cognitoPoolId = "us-east-1_5UwBIwmRq";

module.exports = config;
