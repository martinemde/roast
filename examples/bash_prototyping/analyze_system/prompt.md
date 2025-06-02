# Analyze System Information

Use the bash tool to gather system information including:

1. Operating system details (uname -a)
2. Current disk usage (df -h)
3. Memory information (if available via free -m on Linux or vm_stat on macOS)
4. Current user and groups (whoami, groups)
5. Environment variables (env | grep -E "PATH|HOME|USER")

Gather this information and provide a summary of the system's current state.