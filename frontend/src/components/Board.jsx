import Strike from "./Strike";
import Tile from "./Tile";

function Board({ tiles, onTileClick, playerTurn, strikeClass, player, gameState }) {
  const getTileClassName = (index) => {
    let className = '';
    if (index % 3 !== 2) className += 'right-border ';
    if (index < 6) className += 'bottom-border';
    return className.trim();
};
  
  return (
    <div className="board">
    {Array.from({ length: 9 }, (_, index) => (
      <Tile
        key={index}
        playerTurn={playerTurn}
        onClick={() => onTileClick(index)}
        value={tiles[index]}
        player={player}
        gameState={gameState}
        className={getTileClassName(index)}
      />
    ))}
  <Strike strikeClass={strikeClass} />
</div>
  );
}

export default Board;
