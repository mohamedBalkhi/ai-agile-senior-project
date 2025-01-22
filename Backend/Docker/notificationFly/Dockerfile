FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY NotificationService/NotificationService.csproj NotificationService/
RUN dotnet restore "NotificationService/NotificationService.csproj"

# Copy the rest of the source code
COPY NotificationService/ NotificationService/

WORKDIR "/src/NotificationService"
RUN dotnet build "NotificationService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "NotificationService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .



EXPOSE 8081
ENTRYPOINT ["dotnet", "NotificationService.dll"] 