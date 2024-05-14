const config = {};
config.cognito = {};


config.cognito.clientId = "2d706rph2kvfgnnh4mhlo8vg21";
config.cognito.clientSecret = "tka9daq0cvf7b6v6dqro91cin88vbqinsfgd8415aj00fov3jvr";
config.cognito.loginUrl = "https://tictactoecloud.auth.us-east-1.amazoncognito.com/login?client_id=2d706rph2kvfgnnh4mhlo8vg21&response_type=code&scope=email+openid+phone&redirect_uri=http%3A%2F%2Flocalhost%3A3000";
config.cognito.logoutUrl =
  "https://tictactoecloud.auth.us-east-1.amazoncognito.com/logout?client_id=2d706rph2kvfgnnh4mhlo8vg21&logout_uri=http%3A%2F%2Flocalhost%3A3000";
config.cognito.tokenEndpoint =
  "https://tictactoecloud.auth.us-east-1.amazoncognito.com/oauth2/token";
config.cognito.redirectUri = "http://localhost:3000";
config.cognito.cognitoPoolId = "us-east-1_mGRi4LHMM";

module.exports = config;
