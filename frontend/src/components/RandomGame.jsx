import Input from "./Input";
import { API_URL } from "../App.js";
import { useState, useEffect} from "react";
import TicTacToe from "./TicTacToe.jsx";

function RandomGame(){
    const [initialState, setInitialState] = useState(null);
    const [storedToken, setStoredToken] = useState(null);

    useEffect (() => {
        setStoredToken(localStorage.getItem("jwtToken"));
    }, []);

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

    return (
        <div>
            {!initialState ? (
                <div>
                    {/* {<Input placeholder="Enter nick" onSubmit={handleNickSubmit} />} */}
                    <button onClick={onNewRandomGame}> New random game </button>
                </div>
            ) :
            (
                    <TicTacToe initialState={initialState} />
            )}
        </div>
    );
}

async function getNewRandomGame(storedToken){
    const response = await fetch(`${API_URL}/newGame/random`, {
            method: 'GET',
            credentials: 'include',
            headers: {
              'Authorization': `Bearer ${storedToken}`,
            }
        })
    const game = await response.json();
    return game;
}

export default RandomGame;