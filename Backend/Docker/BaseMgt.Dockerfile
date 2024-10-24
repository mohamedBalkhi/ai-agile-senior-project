FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["BaseMgtService/Senior.AgileAI.BaseMgt.Api/Senior.AgileAI.BaseMgt.Api.csproj", "BaseMgtService/Senior.AgileAI.BaseMgt.Api/"]
COPY ["BaseMgtService/Senior.AgileAI.BaseMgt.Application/Senior.AgileAI.BaseMgt.Application.csproj", "BaseMgtService/Senior.AgileAI.BaseMgt.Application/"]
COPY ["BaseMgtService/Senior.AgileAI.BaseMgt.Domain/Senior.AgileAI.BaseMgt.Domain.csproj", "BaseMgtService/Senior.AgileAI.BaseMgt.Domain/"]
COPY ["BaseMgtService/Senior.AgileAI.BaseMgt.Infrastructure/Senior.AgileAI.BaseMgt.Infrastructure.csproj", "BaseMgtService/Senior.AgileAI.BaseMgt.Infrastructure/"]
RUN dotnet restore "BaseMgtService/Senior.AgileAI.BaseMgt.Api/Senior.AgileAI.BaseMgt.Api.csproj"
COPY BaseMgtService/ .
WORKDIR "/src/Senior.AgileAI.BaseMgt.Api"
RUN dotnet build "Senior.AgileAI.BaseMgt.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Senior.AgileAI.BaseMgt.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Senior.AgileAI.BaseMgt.Api.dll"]

