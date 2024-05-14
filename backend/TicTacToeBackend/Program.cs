using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using System.Security.Claims;
using TicTacToeBackend;
using TicTacToeBackend.DataContext;
using TicTacToeBackend.Models;
using static System.Runtime.InteropServices.JavaScript.JSType;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDistributedMemoryCache();

/*builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(10);
    options.Cookie.HttpOnly = false;
    options.Cookie.IsEssential = true;
    options.Cookie.SameSite = SameSiteMode.Unspecified;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});*/

var clientDomain = Environment.GetEnvironmentVariable("API_DOMAIN");
var clientPort = "3000";

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowStrictOrigin",
        builder =>
        {
            builder.WithOrigins($"{clientDomain}:{clientPort}")
                   .AllowAnyMethod()
                   .AllowAnyHeader()
                   .AllowCredentials();
        });
});


builder.Services.AddSingleton<IGamesContext, GamesRepository>();
builder.Services.AddAuthorization();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer();

builder.Services.ConfigureOptions<JwtBearerConfigureOptions>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowStrictOrigin");

//app.UseSession();

//app.UseHttpsRedirection(); //trouble with authentication

/*app.MapGet("/nick/{nick}", (string nick, HttpContext httpContext) =>
{
    if(nick == null || nick.Trim().Length == 0)
    {
        return Results.BadRequest();
    }
    
    httpContext.Session.SetString("nick", nick);

    return Results.Ok();
});*/

app.MapGet("/newGame/random", (HttpContext httpContext, IGamesContext dataContext) =>
{
    //var sessionId = httpContext.Request.Cookies[".AspNetCore.Session"];
    //var nick = httpContext.Session.GetString("nick");

    var user = httpContext.User;
    var user_id = user.FindFirstValue(ClaimTypes.NameIdentifier);

    if (user_id == null)
    {
        return Results.BadRequest();
    }

    var game = AsignToGame(user_id, user_id, dataContext);
    var (_, playerId) = game.Players[user_id];

    return Results.Ok(new {state=game.State, playerSign = Game.playerSigns[playerId] });
})
.WithOpenApi()
.RequireAuthorization();

app.MapGet("/currentGame", (HttpContext httpContext, IGamesContext dataContext) =>
{
    var user = httpContext.User;
    var user_id = user.FindFirstValue(ClaimTypes.NameIdentifier);

    if (user_id == null)
    {
        return Results.BadRequest();

    }

    var currentGame = GetCurrentGame(user_id, dataContext);

    if (currentGame == null)
    {
        return Results.NotFound();
    }

    return Results.Ok(currentGame.State);
})
.WithOpenApi()
.RequireAuthorization();

app.MapGet("/currentGame/update/{cellIndex}", (int cellIndex, HttpContext httpContext, IGamesContext dataContext) => 
{
    var user = httpContext.User;
    var user_id = user.FindFirstValue(ClaimTypes.NameIdentifier);

    if (user_id == null)
    {
        return Results.BadRequest();
    }

    var state = UpdateGame(cellIndex, user_id, dataContext);

    return state != null ? Results.Ok(state) : Results.BadRequest();
})
.WithOpenApi()
.RequireAuthorization();

app.UseAuthentication();

app.UseAuthorization();

app.Run();

Game GetPendingGame(IGamesContext dataContext) {
    var game = dataContext.GetGames()
        .Where(game => game.Status == GameStatusType.Pending)
        .FirstOrDefault();

    return game;
}

Game GetCurrentGame(string user_id, IGamesContext dataContext)
{
    var game = dataContext.GetGames()
        .Where(game => game.Players.ContainsKey(user_id))
        .LastOrDefault();

    return game;
}

Game AsignToGame(string user_id, string nick, IGamesContext dataContext)
{
    var pendingGame = GetPendingGame(dataContext);
    var currentGame = GetCurrentGame(user_id, dataContext);

    if (currentGame != null && currentGame.Status != GameStatusType.Finished)
    {
        currentGame.Status = GameStatusType.Finished;
        currentGame.Result = GameResultType.Canceled;

        if (currentGame.Id == pendingGame.Id)
        {
            pendingGame = null;
        }
    }

    if (pendingGame == null)
    {
        pendingGame = new Game();
        pendingGame.Players.Add(user_id, (nick, PlayerType.X_Player));
        dataContext.AddGame(pendingGame);
    }
    else
    {
        pendingGame.Players.Add(user_id, (nick, PlayerType.O_Player));
        pendingGame.Status = GameStatusType.InProgress;
        dataContext.UpdateGame(pendingGame);
    }

    return pendingGame;
}

GameState UpdateGame(int cellIndex, string user_id, IGamesContext dataContext)
{
    var currentGame = GetCurrentGame(user_id, dataContext);
    var currentState = currentGame.State;
    var (_, playerId) = currentGame.Players[user_id];

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