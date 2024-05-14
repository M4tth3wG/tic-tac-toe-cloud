import "./App.css";
import { useState, useEffect } from "react";
import RandomGame from "./components/RandomGame";

// const API_DOMAIN = process.env.REACT_APP_API_DOMAIN;
// const API_PORT = process.env.REACT_APP_API_PORT;
const API_DOMAIN = "http://localhost";
const API_PORT = 32771;
const config = require("./config");
export const API_URL = `${API_DOMAIN}:${API_PORT}`;


function App() {
  const [token, setToken] = useState(localStorage.getItem("jwtToken"));

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const code = params.get("code");

    if (code) {
      fetchToken(code)
    }
  }, []);

  function fetchToken(code) {
    fetch(config.cognito.tokenEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        client_id: config.cognito.clientId,
        client_secret: config.cognito.clientSecret,
        code: code,
        redirect_uri: config.cognito.redirectUri,
      }).toString(),
    })
    .then((response) => {
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      return response.json();
    })
    .then((data) => {
      setToken(data.access_token)
      localStorage.setItem("jwtToken", data.access_token);
      localStorage.setItem("refreshToken", data.refresh_token);
    })
    .catch((error) => {
      console.error("There was a problem with your fetch operation:", error);
    });
  }

  function logOut(){
    document.cookie = "cognito=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie = "test=;";
    localStorage.removeItem("jwtToken");
    localStorage.removeItem("refreshToken");
    setToken("");

    fetch(config.cognito.logoutUrl, {
      method: "GET",
      mode: "no-cors",
      headers: {  
        Authorization: `Bearer ${token}`,
      },
    })
      .then((response) => {})
      .catch((error) => {
        console.error("Error logging out:", error);
      });
  }

  return token ? (
    <div>
      <div>
      <button onClick={logOut} class="logout-button"> Log out </button>
      </div>
      <div>
        <RandomGame />
      </div>
    </div>
  ) : (
    <div>
      <a href={config.cognito.loginUrl} rel="noopener noreferrer">
        <button className="login-button">Login</button>
      </a>
    </div>
  );
}

export async function refreshAccessToken(refreshToken){
  const newToken = await fetch(config.cognito.tokenEndpoint, {
    method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "refresh_token",
        client_id: config.cognito.clientId,
        client_secret: config.cognito.clientSecret,
        refresh_token: refreshToken,
      }).toString(),
    })
    .then((response) => {
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
        return response.json();
      })
    .then((data) => {
        return data.access_token
    });

    return newToken;
}

export default App;
