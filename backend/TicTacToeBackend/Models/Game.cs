using System;

namespace TicTacToeBackend.Models
{
    public class Game
    {
        public static readonly int boardSize = 9;
        public static readonly string[] playerSigns = ["X", "O"];
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

public Guid Id { get; } = new Guid();
        public Dictionary<string, (string, int)> Players { get; set; } = new Dictionary<string, (string, int)>();

        public GameState State { get; set; } = new GameState();

        public GameStatusType Status { 
            get { return State.Status; }
            set { State.Status = value; } 
        }

        public bool CheckWin()
        {
            var isWin = winningCombinations.Any(
                combination => combination
                    .All(index => State.CurrentPlayerSign
                            .Equals(State.Board[index]
                )));

            if (isWin)
            {
                State.Status = GameStatusType.Finished;
            }

            return isWin;
        }
    }
}
