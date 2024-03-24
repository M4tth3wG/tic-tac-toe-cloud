namespace TicTacToeBackend.Models
{
    public class GameState
    {
        public string[] Board { get; set; }
        public string CurrentPlayerSign { get { return Game.playerSigns[CurrentPlayerId]; } }
        public int CurrentPlayerId { get; set; }
        public GameStatusType Status { get; set; }

        public GameState()
        {
            Board = new string[Game.boardSize];
            CurrentPlayerId = 0;
            Status = GameStatusType.Pending;
        }
    }

    public enum GameStatusType {
        Pending,
        InProgress,
        Finished
    }
}
