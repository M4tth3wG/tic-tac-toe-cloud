using Microsoft.AspNetCore.Http;
using TicTacToeBackend.DataContext;
using TicTacToeBackend.Models;
using static System.Runtime.InteropServices.JavaScript.JSType;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(10);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddSingleton<IGamesContext, GamesRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSession();

app.UseHttpsRedirection();

app.MapGet("/nick/{nick}", (string nick, HttpContext httpContext) =>
{
    httpContext.Session.SetString("nick", nick);

    return Results.Ok();
});

app.MapGet("/newGame/random", (HttpContext httpContext, IGamesContext dataContext) =>
{
    var sessionId = httpContext.Request.Cookies[".AspNetCore.Session"];
    var nick = httpContext.Session.GetString("nick");

    if (sessionId == null || nick == null)
    {
        return Results.BadRequest();
    }

    var game = AsignToGame(sessionId, nick, dataContext);

    return Results.Ok(game.State);
})
.WithOpenApi();

app.MapGet("/currentGame", (HttpContext httpContext, IGamesContext dataContext) =>
{
    var sessionId = httpContext.Request.Cookies[".AspNetCore.Session"];

    if (sessionId == null)
    {
        return Results.BadRequest();
    }

    var currentGame = GetCurrentGame(sessionId, dataContext);

    if (currentGame == null)
    {
        return Results.NotFound();
    }

    return Results.Ok(currentGame.State);
})
.WithOpenApi();

app.MapGet("/currentGame/update/{cellIndex}", (int cellIndex, HttpContext httpContext, IGamesContext dataContext) => 
{
    var sessionId = httpContext.Request.Cookies[".AspNetCore.Session"];

    if (sessionId == null)
    {
        return Results.BadRequest();
    }

    var state = UpdateGame(cellIndex, sessionId, dataContext);

    return state != null ? Results.Ok(state) : Results.BadRequest();
})
.WithOpenApi();

app.Run();

Game GetPendingGame(IGamesContext dataContext) {
    var game = dataContext.GetGames()
        .Where(game => game.Status == GameStatusType.Pending)
        .FirstOrDefault();

    return game;
}

Game GetCurrentGame(string sessionId, IGamesContext dataContext)
{
    var game = dataContext.GetGames()
        .Where(game => game.Players.ContainsKey(sessionId))
        .LastOrDefault();

    return game;
}

Game AsignToGame(string sessionId, string nick, IGamesContext dataContext)
{
    var pendingGame = GetPendingGame(dataContext);

    if (pendingGame == null)
    {
        pendingGame = new Game();
        pendingGame.Players.Add(sessionId, (nick, 0));
        dataContext.AddGame(pendingGame);
    }
    else
    {
        pendingGame.Players.Add(sessionId, (nick, 1));
        pendingGame.Status = GameStatusType.InProgress;
        dataContext.UpdateGame(pendingGame);
    }

    return pendingGame;
}

GameState UpdateGame(int cellIndex, string sessionId, IGamesContext dataContext)
{
    var currentGame = GetCurrentGame(sessionId, dataContext);
    var currentState = currentGame.State;
    var (_, playerId) = currentGame.Players[sessionId];

    if (playerId == currentState.CurrentPlayerId
        && cellIndex >= 0 && cellIndex < Game.boardSize
        && currentState.Board[cellIndex] == null
        && currentState.Status == GameStatusType.InProgress)
    {
        currentState.Board[cellIndex] = Game.playerSigns[playerId];
        currentGame.CheckWin();
        currentState.CurrentPlayerId = (currentState.CurrentPlayerId + 1) % 2;
        dataContext.UpdateGame(currentGame);
        return currentState;
    }
    
    return null;
}