# DockerizeDotNet

A containerized .NET solution demonstrating Docker deployment for .NET applications including a Web API and Azure Functions.

## Project Structure

- **DotNetApi**: Main ASP.NET Core Web API project
- **WebApiDb**: Database access library
- **TestTimer**: Azure Functions project with timer functionality

## Prerequisites

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Docker](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)
- PowerShell 5.1+

## Quick Start

1. Clone the repository
2. Configure the build arguments (see Configuration section)
3. Run the build script:

```powershell
.\build-and-run.ps1
```

## Configuration

### Build Arguments

Create a `.build-args` file in the root directory (based on `.build-args.example`) with the following options:

```
USE_CACHE=true
PUSH_TO_REGISTRY=false
REGISTRY_URL=myregistry.azurecr.io
REGISTRY_USERNAME=username
REGISTRY_PASSWORD=password
USE_UNIQUE_SUFFIX=false
SUFFIX_TYPE=timestamp
BUILD_NUMBER=1001
```

### Configuration Options

| Option | Description | Values |
|--------|-------------|--------|
| `USE_CACHE` | Whether to use Docker build cache | `true`/`false` |
| `PUSH_TO_REGISTRY` | Push images to container registry | `true`/`false` |
| `REGISTRY_URL` | Container registry URL | e.g., `myregistry.azurecr.io` |
| `REGISTRY_USERNAME` | Registry username | Your username |
| `REGISTRY_PASSWORD` | Registry password | Your password |
| `USE_UNIQUE_SUFFIX` | Add unique suffix to image tags | `true`/`false` |
| `SUFFIX_TYPE` | Type of unique suffix | `timestamp`, `date`, or `buildnum` |
| `BUILD_NUMBER` | Build number to use with `buildnum` suffix type | Any numeric value |

### Environment Variables

Environment variables should be defined in the `.env` file for the DotNetApi project (see `.env.example`).

## Deployment Process

The `build-and-run.ps1` script handles the following:

1. Reads configuration from `.build-args`
2. Builds Docker images using docker-compose
3. Applies unique suffixes to image tags if configured
4. Deploys containers locally using docker-compose
5. Optionally pushes images to a container registry

### Running the Build Script

```powershell
# Basic usage
.\build-and-run.ps1

# To see detailed output
.\build-and-run.ps1 -Verbose
```

## Adding Projects to the Solution

To add additional projects to the solution:

```powershell
cd DotNetApi
dotnet sln DotNetApi.sln add ..\NewProject\NewProject.csproj
```

## Troubleshooting

- If the script fails, check Docker is running
- Verify the `.build-args` file exists and has correct formatting
- Ensure proper network connectivity for registry pushing
- Check `.env` file for any required environment variables

## License

This project is licensed under the MIT License.