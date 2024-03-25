import GameState from "../enums/GameState";

function TurnDisplay({gameState, playerTurn, player}){
  if (gameState !== GameState.inProgress || playerTurn === null) {
    return null;
  }

  return (
    <div className="turn-display">
      {playerTurn === player ? "Your turn" : "Enemy's turn"}
    </div>
  );
}

export default TurnDisplay;