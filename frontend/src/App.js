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
  const [token, setToken] = useState("");

  useEffect(() => {
    const storedToken = localStorage.getItem("jwtToken");

    if (storedToken) {
      setToken(storedToken);
    }
  }, []);

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
    localStorage.removeItem("jwtToken");
    localStorage.removeItem("refreshToken");
    setToken("");

    fetch(config.cognito.logoutUrl, {
      method: "GET",
    })
    .then((response) => {
    
    })
    .catch((error) => {
      console.error("Error logging out:", error);
    });
  }

  return (
    <div>
      <button onClick={logOut}> Log out </button>

      {token !== "" ? (
        <RandomGame />
      ) : (
        <div>
          <a href={config.cognito.loginUrl} rel="noopener noreferrer">
            <button>Login</button>
          </a>
        </div>
      )}
    </div>
  );
}

function refreshToken(refreshToken){
  fetch(config.cognito.tokenEndpoint, {
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
}

export default App;
