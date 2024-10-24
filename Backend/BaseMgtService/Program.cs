using Microsoft.EntityFrameworkCore;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using Senior.AgileAI.BaseMgt.Infrastructure.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddDbContext<PostgreSqlAppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Learn more about configuring WebAPI at https://go.microsoft.com/fwlink/?LinkID=398940

var app = builder.Build();

// Configure the HTTP request pipeline.

app.Run();
