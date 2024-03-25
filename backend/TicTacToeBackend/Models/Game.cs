using System;

namespace TicTacToeBackend.Models
{
    public class Game
    {
        public static readonly int boardSize = 9;
        public static readonly Dictionary<PlayerType, string> playerSigns = new Dictionary<PlayerType, string>() { { PlayerType.X_Player, "X" }, { PlayerType.O_Player, "O" } };
        private readonly List<List<int>> winningCombinations = [
                [0, 1, 2],
                [3, 4, 5],
                [6, 7, 8],
                [0, 3, 6],
                [1, 4, 7],
                [2, 5, 8],
                [0, 4, 8],
                [2, 4, 6]
            ];

        public Guid Id { get; } = Guid.NewGuid();
        public Dictionary<string, (string, PlayerType)> Players { get; set; } = new Dictionary<string, (string, PlayerType)>();

        public GameState State { get; set; } = new GameState();

        public GameStatusType Status { 
            get { return State.Status; }
            set { State.Status = value; } 
        }

        public GameResultType? Result
        {
            get { return State.Result; }
            set { State.Result = value; }
        }

        public bool CheckIfFinished()
        {
            var isFinished = winningCombinations.Any(
                combination => combination
                    .All(index => State.CurrentPlayerSign
                            .Equals(State.Board[index]
                )));

            if (isFinished)
            {
                State.Status = GameStatusType.Finished;
                Result = State.CurrentPlayerType == PlayerType.X_Player ? GameResultType.X_PlayerWon : GameResultType.O_PlayerWon;
            }

            isFinished = CheckForDraw();

            return isFinished;
        }

        public bool CheckForDraw()
        {
            var isDraw = State.Board.All(cell => cell != null);

            if (isDraw)
            {
                State.Status = GameStatusType.Finished;
                Result = GameResultType.Draw;
            }

            return isDraw;
        }
    }
}
