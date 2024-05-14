import Input from "./Input";
import { API_URL } from "../App.js";
import { useState, useEffect} from "react";
import TicTacToe from "./TicTacToe.jsx";
import refreshAccessToken from "../App.js"

function RandomGame(){
    const [initialState, setInitialState] = useState(null);
    const [storedToken, setStoredToken] = useState(localStorage.getItem("jwtToken"));

    function onNewRandomGame() {
        if(!storedToken){
            setStoredToken(localStorage.getItem("jwtToken"));
        }
        else{
            getNewRandomGame(storedToken).then(result => {
                setInitialState(result);
            }).catch(error => {
            console.error('Error initializing game:', error);
            });
        }
    };

    async function getNewRandomGame(storedToken){
        const response = await fetch(`${API_URL}/newGame/random`, {
                method: 'GET',
                headers: {
                'Authorization': `Bearer ${storedToken}`,
                }
            })

        if (response.status === 401){
            const refreshToken = localStorage.getItem("refreshToken");
            const newToken = refreshAccessToken(refreshToken);

            localStorage.setItem("jwtToken", newToken);
            setStoredToken(newToken)
            return 
        }

        const game = await response.json();
        return game;
}

    return (
        <div>
            {!initialState ? (
                <div>
                    <button onClick={onNewRandomGame}> New random game </button>
                </div>
            ) :
            (
                <TicTacToe initialState={initialState} />
            )}
        </div>
    );
}



export default RandomGame;