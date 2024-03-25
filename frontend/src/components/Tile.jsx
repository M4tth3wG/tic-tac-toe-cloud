import GameState from "../enums/GameState";

function Tile({ className, value, onClick, playerTurn, player, gameState }) {
  let hoverClass = '';
  if (value == null && playerTurn === player && playerTurn != null && gameState === GameState.inProgress) {
    hoverClass = `${playerTurn.toLowerCase()}-hover`;
  }
  return (
    <div onClick={onClick} className={`tile ${className} ${hoverClass}`}>
      {value}
    </div>
  );
}

export default Tile;
