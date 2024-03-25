import GameResult from "../enums/GameResult";

function GameOver({ gameResult }) {
  switch (gameResult) {
    case GameResult.x_PlayerWon:
      return <div className="game-over">X Wins</div>;
    case GameResult.o_PlayerWon:
      return <div className="game-over">O Wins</div>;
    case GameResult.draw:
      return <div className="game-over">Draw</div>;
      case GameResult.canceled:
      return <div className="game-over">Game canceled</div>;
    default:
      return <></>;
  }
}

export default GameOver;
