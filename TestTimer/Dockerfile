FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["TestTimer/TestTimer.csproj", "TestTimer/"]
RUN dotnet restore "TestTimer/TestTimer.csproj"
COPY . .
WORKDIR "/src/TestTimer"
RUN dotnet build "TestTimer.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "TestTimer.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0
WORKDIR /home/site/wwwroot
COPY --from=publish /app/publish .
ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true
ENV FUNCTIONS_WORKER_RUNTIME=dotnet-isolated
EXPOSE 80
CMD ["dotnet", "Microsoft.Azure.Functions.Worker.Sdk.Generator.dll", "start", "--port", "80"]
