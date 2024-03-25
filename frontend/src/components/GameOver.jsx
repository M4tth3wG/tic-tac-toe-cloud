import GameResult from "../enums/GameResult";

function GameOver({ gameResult, playerTurn, player }) {
  switch (gameResult) {
    case GameResult.x_PlayerWon:
    case GameResult.o_PlayerWon:
      if(player !== playerTurn){
        return <div className="game-over">You won</div>;
      }
      else {
        return <div className="game-over">You lost</div>;
      }    
    case GameResult.draw:
      return <div className="game-over">Draw</div>;
    case GameResult.canceled:
      return <div className="game-over">Game canceled</div>;
    default:
      return <></>;
  }
}

export default GameOver;
