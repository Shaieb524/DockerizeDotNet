# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Generate dev certificate on Windows host machine for localhost ONLY (not for production)
ARG HTTPS_CERT_PASSWORD
RUN mkdir -p /https && \
    dotnet dev-certs https -ep /https/aspnetapp.pfx -p $HTTPS_CERT_PASSWORD && \
    dotnet dev-certs https --trust

ARG BUILD_CONFIGURATION=Release

WORKDIR /src

COPY ["DotNetApi/DotNetApi.csproj", "DotNetApi/"]
COPY ["WebApiDb/WebApiDb.csproj", "WebApiDb/"]

RUN dotnet restore "DotNetApi/DotNetApi.csproj"

COPY . .
WORKDIR "/src/DotNetApi"
RUN dotnet build "./DotNetApi.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./DotNetApi.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Copy certificate from build stage
# Though it is not recommended to copy the certificate from build stage to final stage, it is done here for simplicity
# For production, it is recommended to use a secure way to copy the certificate to the final stage such as using some key vault
# or at least mount the certificate from a secure location
COPY --from=build /https/aspnetapp.pfx /https/

ENTRYPOINT ["dotnet", "DotNetApi.dll"]