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
    options.Cookie.HttpOnly = false;
    options.Cookie.IsEssential = true;
    options.Cookie.SameSite = SameSiteMode.Unspecified;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowStrictOrigin",
        builder =>
        {
            builder.WithOrigins("http://54.144.51.154:3000") // TODO
                   .AllowAnyMethod()
                   .AllowAnyHeader()
                   .AllowCredentials();
        });
});


builder.Services.AddSingleton<IGamesContext, GamesRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowStrictOrigin");

app.UseSession();

app.UseHttpsRedirection();

app.MapGet("/nick/{nick}", (string nick, HttpContext httpContext) =>
{
    if(nick == null || nick.Trim().Length == 0)
    {
        return Results.BadRequest();
    }
    
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
    var (_, playerId) = game.Players[sessionId];

    return Results.Ok(new {state=game.State, playerSign = Game.playerSigns[playerId] });
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
    var currentGame = GetCurrentGame(sessionId, dataContext);

    if (currentGame != null && currentGame.Status != GameStatusType.Finished)
    {
        currentGame.Status = GameStatusType.Finished;
        currentGame.Result = GameResultType.Canceled;
    }

    if (pendingGame == null)
    {
        pendingGame = new Game();
        pendingGame.Players.Add(sessionId, (nick, PlayerType.X_Player));
        dataContext.AddGame(pendingGame);
    }
    else
    {
        pendingGame.Players.Add(sessionId, (nick, PlayerType.O_Player));
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

    if (playerId == currentState.CurrentPlayerType
        && cellIndex >= 0 && cellIndex < Game.boardSize
        && currentState.Board[cellIndex] == null
        && currentState.Status == GameStatusType.InProgress)
    {
        currentState.Board[cellIndex] = Game.playerSigns[playerId];
        currentGame.CheckIfFinished();
        currentState.CurrentPlayerType = (PlayerType)(((int)currentState.CurrentPlayerType + 1) % 2);
        dataContext.UpdateGame(currentGame);
        return currentState;
    }
    
    return null;
}