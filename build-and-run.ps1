# Read build args and convert to --build-arg flags
$buildArgs = Get-Content .\.build-args | Where-Object { $_ -match '=' }
$buildArgFlags = $buildArgs | ForEach-Object { "--build-arg " + $_ } | Join-String -Separator " "
Write-Host "Build args: $buildArgFlags"

# Process build arguments into variables
$useCache = $false
$pushToRegistry = $false
$registryUrl = ""
$registryUser = ""
$registryPassword = ""
$useUniqueSuffix = $false
$suffixType = "timestamp" # Options: timestamp, date, buildnum

foreach ($arg in $buildArgs) {
    if ($arg -match "USE_CACHE=(.+)") {
        $useCache = [System.Convert]::ToBoolean($matches[1])
    }
    elseif ($arg -match "PUSH_TO_REGISTRY=(.+)") {
        $pushToRegistry = [System.Convert]::ToBoolean($matches[1])
    }
    elseif ($arg -match "REGISTRY_URL=(.+)") {
        $registryUrl = $matches[1]
    }
    elseif ($arg -match "REGISTRY_USERNAME=(.+)") {
        $registryUser = $matches[1]
    }
    elseif ($arg -match "REGISTRY_PASSWORD=(.+)") {
        $registryPassword = $matches[1]
    }
    elseif ($arg -match "USE_UNIQUE_SUFFIX=(.+)") {
        $useUniqueSuffix = [System.Convert]::ToBoolean($matches[1])
    }
    elseif ($arg -match "SUFFIX_TYPE=(.+)") {
        $suffixType = $matches[1]
    }
    elseif ($arg -match "BUILD_NUMBER=(.+)") {
        $buildNumber = $matches[1]
    }
}

# Generate unique suffix based on selected type
$uniqueSuffix = ""
if ($useUniqueSuffix) {
    switch ($suffixType) {
        "timestamp" {
            $uniqueSuffix = Get-Date -Format "yyyyMMddHHmmss"
        }
        "date" {
            $uniqueSuffix = Get-Date -Format "yyyyMMdd"
        }
        "buildnum" {
            # Use build number if provided, otherwise use timestamp
            if ([string]::IsNullOrEmpty($buildNumber)) {
                $buildNumber = Get-Date -Format "HHmmss"
            }
            $uniqueSuffix = $buildNumber
        }
        default {
            $uniqueSuffix = Get-Date -Format "yyyyMMddHHmmss"
        }
    }
    Write-Host "Using unique suffix for images: $uniqueSuffix"
}

# Determine whether to use --no-cache
$cacheFlag = if (-not $useCache) { "--no-cache" } else { "" }
Write-Host "Cache setting: $(if($useCache){'Using cache'}else{'No cache'})"

# Build the Docker images
$buildCommand = "docker-compose build $cacheFlag $buildArgFlags"
Write-Host "Executing: $buildCommand"
$buildResult = Invoke-Expression $buildCommand

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully."
    
    # Get the original image names
    $originalImages = docker-compose config --images
    $taggedImages = @{}
    
    # Tag images with unique suffix if enabled
    if ($useUniqueSuffix) {
        foreach ($image in $originalImages) {
            $imageBase = $image
            if ($image -match ":") {
                $parts = $image -split ":"
                $imageBase = $parts[0]
                $tag = $parts[1]
                $newTag = "$tag-$uniqueSuffix"
            } else {
                $newTag = "latest-$uniqueSuffix"
            }
            
            $taggedImage = "$imageBase`:$newTag"
            Write-Host "Tagging image: $image as $taggedImage"
            docker tag $image $taggedImage
            
            # Store mapping of original to tagged image
            $taggedImages[$image] = $taggedImage
        }
    } else {
        # If not using unique suffix, keep original image names
        foreach ($image in $originalImages) {
            $taggedImages[$image] = $image
        }
    }
    
    # Run the containers after building
    # Note: This will still use the original image names from docker-compose.yml
    $runCommand = "docker-compose up -d"
    Write-Host "Executing: $runCommand"
    Invoke-Expression $runCommand
    
    # Push images to registry if enabled
    if ($pushToRegistry -and -not [string]::IsNullOrEmpty($registryUrl)) {
        Write-Host "Preparing to push images to registry: $registryUrl"
        
        # Perform Docker login if credentials are provided
        $loginSuccess = $false
        if (-not [string]::IsNullOrEmpty($registryUser) -and -not [string]::IsNullOrEmpty($registryPassword)) {
            Write-Host "Logging in to Docker registry: $registryUrl"
            $registryPassword | docker login $registryUrl -u $registryUser --password-stdin
            
            if ($LASTEXITCODE -eq 0) {
                $loginSuccess = $true
                Write-Host "Successfully logged in to Docker registry" -ForegroundColor Green
            } else {
                Write-Host "Failed to log in to Docker registry" -ForegroundColor Red
            }
        } else {
            Write-Host "No registry credentials provided. Assuming you're already logged in." -ForegroundColor Yellow
            $loginSuccess = $true
        }
        
        # Continue with pushing if login was successful
        if ($loginSuccess) {
            foreach ($image in $taggedImages.Keys) {
                $taggedImage = $taggedImages[$image]
                
                # Create registry version of the image name
                $registryImage = "$registryUrl/$taggedImage"
                Write-Host "Tagging image: $taggedImage as $registryImage"
                docker tag $taggedImage $registryImage
                
                # Push the image
                Write-Host "Pushing image: $registryImage"
                docker push $registryImage
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed to push image $registryImage" -ForegroundColor Red
                } else {
                    Write-Host "Successfully pushed $registryImage" -ForegroundColor Green
                }
            }
        }
    }
} else {
    Write-Host "Build failed. Not starting containers or pushing images." -ForegroundColor Red
}