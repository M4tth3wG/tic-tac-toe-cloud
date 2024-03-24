using TicTacToeBackend.Models;

namespace TicTacToeBackend.DataContext
{
    public class GamesRepository : IGamesContext
    {
        private readonly Dictionary<Guid, Game> games = new Dictionary<Guid, Game>();

        public void AddGame(Game game)
        {
            games.Add(game.Id, game);
        }

        public Game GetGame(Guid id)
        {
            return games.GetValueOrDefault(id);
        }

        public IEnumerable<Game> GetGames()
        {
            return games.Values;
        }

        public void RemoveGame(Guid id)
        {
            games.Remove(id);
        }

        public void UpdateGame(Game game)
        {
            games[game.Id] = game;
        }
    }
}
