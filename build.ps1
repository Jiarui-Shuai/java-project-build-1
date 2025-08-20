# 获取主类名
$mainClass = Read-Host "Enter the main class name (e.g., com.example.Main)"

# 设置日志文件路径
$logDir = "logs"
$logFile = "$logDir\build_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$OutputName = Read-Host "Enter the name of the output file (e.g., myapp.jar)"
$buildName = "build\" + $OutputName

# 创建日志目录（如果不存在）
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
    Write-Host "Created log directory: $logDir" -ForegroundColor Yellow
}

# 日志函数
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # 写入控制台
    Write-Host $logEntry -ForegroundColor $Color
    
    # 写入日志文件
    Add-Content -Path $logFile -Value $logEntry
}

try {
    Write-Log "Starting build process..." "INFO" "Green"
    Write-Log "Main class specified: $mainClass" "INFO" "Cyan"
    
    # 检查源代码目录是否存在
    if (-not (Test-Path "src")) {
        Write-Log "Source directory 'src' does not exist. Please create it and place your .java files there." "ERROR" "Red"
        exit 1
    }

    # 创建构建目录（如果不存在）
    if (-not (Test-Path "bin")) {
        New-Item -ItemType Directory -Path "bin" | Out-Null
        Write-Log "Created directory: bin" "INFO" "Yellow"
    }

    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" | Out-Null
        Write-Log "Created directory: build" "INFO" "Yellow"
    }

    # 获取所有 Java 文件
    $javaFiles = Get-ChildItem -Path "src" -Filter "*.java" -Recurse
    Write-Log "Found $($javaFiles.Count) Java files in src directory" "INFO" "Cyan"

    if ($javaFiles.Count -eq 0) {
        Write-Log "No Java files found in src directory." "ERROR" "Red"
        exit 1
    }

    # 编译 Java 文件
    Write-Log "Compiling Java source files..." "INFO" "Green"
    $compileOutput = javac -d bin @($javaFiles.FullName) 2>&1
    
    # 记录编译输出
    if ($compileOutput) {
        Write-Log "Compilation output: $compileOutput" "DEBUG" "Gray"
    }

    # 检查编译是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Compilation failed. Please check your Java code." "ERROR" "Red"
        exit 1
    }
    
    Write-Log "Compilation completed successfully" "INFO" "Green"

    # 创建 JAR 文件
    Write-Log "Creating JAR file..." "INFO" "Green"
    $jarOutput = jar cvfe build\$buildName.jar $mainClass -C bin . 2>&1
    
    # 记录JAR创建输出
    if ($jarOutput) {
        Write-Log "JAR creation output: $jarOutput" "DEBUG" "Gray"
    }

    # 检查 JAR 创建是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Log "JAR creation failed." "ERROR" "Red"
        exit 1
    }

    Write-Log "Build completed successfully! JAR file: build\myapp.jar" "INFO" "Green"
    Write-Log "Log file saved to: $logFile" "INFO" "Cyan"
}
catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" "ERROR" "Red"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "DEBUG" "Gray"
    exit 1
}