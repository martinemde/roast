# System Exploration with Unrestricted Bash

You have access to the unrestricted `bash` function. Use it to explore the system and demonstrate capabilities that would not be available with the restricted Cmd tool.

**IMPORTANT**: This is a demonstration in a trusted environment. Show responsible usage while highlighting the flexibility.

Perform the following explorations:

1. **System Information**:
   - Get system info: `uname -a`
   - Check disk usage: `df -h | head -5`
   - Show current user: `whoami`

2. **Process Information**:
   - List running processes: `ps aux | head -10`
   - Show system uptime: `uptime`

3. **Network Information** (if available):
   - Show network interfaces: `ifconfig || ip addr` (try both as availability varies)
   - Check connectivity: `ping -c 2 8.8.8.8 || echo "Ping not available"`

4. **Package Management** (demonstrate but don't actually install):
   - Check if brew is available: `which brew && brew --version`
   - Check Ruby gems: `gem list | head -5`

Remember: With great power comes great responsibility. Always consider security implications.

RESPONSE FORMAT
Summarize your findings in JSON:

<json>
{
  "system_exploration": {
    "system_info": {
      "os": "Operating system details",
      "architecture": "System architecture",
      "hostname": "System hostname"
    },
    "resource_usage": {
      "disk_usage": "Summary of disk usage",
      "processes": "Number of running processes",
      "uptime": "System uptime"
    },
    "capabilities_demonstrated": [
      "List of commands that wouldn't work with restricted Cmd tool"
    ],
    "security_note": "This demonstrates why Bash tool should only be used in trusted environments"
  }
}
</json>