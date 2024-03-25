import Strike from "./Strike";
import Tile from "./Tile";

function Board({ tiles, onTileClick, playerTurn, strikeClass, player, gameState }) {
  return (
    <div className="board">
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(0)}
        value={tiles[0]}
        player={player}
        gameState={gameState}
        className="right-border bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(1)}
        value={tiles[1]}
        player={player}
        gameState={gameState}
        className="right-border bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(2)}
        value={tiles[2]}
        player={player}
        gameState={gameState}
        className=" bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(3)}
        value={tiles[3]}
        player={player}
        gameState={gameState}
        className="right-border bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(4)}
        value={tiles[4]}
        player={player}
        gameState={gameState}
        className="right-border bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(5)}
        value={tiles[5]}
        player={player}
        gameState={gameState}
        className="bottom-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(6)}
        value={tiles[6]}
        player={player}
        gameState={gameState}
        className="right-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(7)}
        value={tiles[7]}
        player={player}
        gameState={gameState}
        className="right-border"
      />
      <Tile
        playerTurn={playerTurn}
        onClick={() => onTileClick(8)}
        player={player}
        gameState={gameState}
        value={tiles[8]}
      />
      <Strike strikeClass={strikeClass} />
    </div>
  );
}

export default Board;
