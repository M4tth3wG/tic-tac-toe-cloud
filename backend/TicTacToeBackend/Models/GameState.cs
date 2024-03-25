using TicTacToeBackend.Models;

namespace TicTacToeBackend.Models
{
    public class GameState
    {
        public string[] Board { get; set; }
        public string CurrentPlayerSign { get { return Game.playerSigns[CurrentPlayerType]; } }
        public PlayerType CurrentPlayerType { get; set; }
        public GameStatusType Status { get; set; }
        public GameResultType? Result { get; set; }

        public GameState()
        {
            Board = new string[Game.boardSize];
            CurrentPlayerType = PlayerType.X_Player;
            Status = GameStatusType.Pending;
            Result = null;
        }
    }

    public enum GameStatusType {
        Pending = 0,
        InProgress = 1,
        Finished = 2
    }

    public enum GameResultType
    {
        Canceled = 0,
        X_PlayerWon = 1,
        O_PlayerWon = 2,
        Draw = 3
    }

    public enum PlayerType { X_Player = 0,  O_Player = 1 }
}