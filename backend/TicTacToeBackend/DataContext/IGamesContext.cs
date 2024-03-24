using TicTacToeBackend.Models;

namespace TicTacToeBackend.DataContext
{
    public interface IGamesContext
    {

        IEnumerable<Game> GetGames();
        Game GetGame(Guid id);
        void AddGame(Game game);
        void RemoveGame(Guid id);
        void UpdateGame(Game game);
    }
}
