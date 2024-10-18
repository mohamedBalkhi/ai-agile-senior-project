using Senior.AgileAI.BaseMgt.Infrastructure.Extensions;
using Senior.AgileAI.BaseMgt.Infrastructure;
using Senior.AgileAI.BaseMgt.Application;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddPostgreSqlAppDbContext(builder.Configuration); // ? PostgreSql
builder.Services.AddInfrastructureServices(); // ? DI Of Infrastrcture.
builder.Services.AddApplicationServices(); // ? DI Of Application.
builder.Services.AddControllers(); 
builder.Services.AddEndpointsApiExplorer(); 
builder.Services.AddSwaggerGen();

// Add authentication
// builder.Services.AddAuthentication().AddJwtBearer();

// Add authorization
builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.UseExceptionHandler("/Error");
app.UseStatusCodePages();

app.Run();
