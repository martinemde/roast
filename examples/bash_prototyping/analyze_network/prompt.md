# Analyze Network Configuration

Use the bash tool to gather network information:

1. Check network interfaces (ifconfig or ip addr)
2. Display routing table (netstat -nr or ip route)
3. Check listening ports (netstat -an | grep LISTEN or lsof -i -P | grep LISTEN)
4. Test DNS resolution (nslookup example.com or dig example.com)
5. Check current network connections

Provide a summary of the network configuration and any interesting findings.

Note: Some commands may require different syntax on macOS vs Linux.