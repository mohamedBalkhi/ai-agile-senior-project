FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY BaseMgtService/Senior.AgileAI.BaseMgt.Api/Senior.AgileAI.BaseMgt.Api.csproj BaseMgtService/Senior.AgileAI.BaseMgt.Api/
COPY BaseMgtService/Senior.AgileAI.BaseMgt.Application/Senior.AgileAI.BaseMgt.Application.csproj BaseMgtService/Senior.AgileAI.BaseMgt.Application/
COPY BaseMgtService/Senior.AgileAI.BaseMgt.Domain/Senior.AgileAI.BaseMgt.Domain.csproj BaseMgtService/Senior.AgileAI.BaseMgt.Domain/
COPY BaseMgtService/Senior.AgileAI.BaseMgt.Infrastructure/Senior.AgileAI.BaseMgt.Infrastructure.csproj BaseMgtService/Senior.AgileAI.BaseMgt.Infrastructure/

# Restore dependencies
RUN dotnet restore "BaseMgtService/Senior.AgileAI.BaseMgt.Api/Senior.AgileAI.BaseMgt.Api.csproj"

# Copy the rest of the source code
COPY BaseMgtService/ BaseMgtService/

WORKDIR "/src/BaseMgtService/Senior.AgileAI.BaseMgt.Api"
RUN dotnet build "Senior.AgileAI.BaseMgt.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Senior.AgileAI.BaseMgt.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

# Install FFmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg curl && \
    rm -rf /var/lib/apt/lists/*
    
WORKDIR /app
COPY --from=publish /app/publish .



# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["dotnet", "Senior.AgileAI.BaseMgt.Api.dll"]
