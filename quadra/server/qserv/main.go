package main

import (
	"flag"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// Config holds runtime configuration
var Config = struct {
	DataDir      string
	Debug        int
	Port         string
	PublicIP     string
	ScoresToKeep int
	Timeout      int
}{
	ScoresToKeep: 100,
	Timeout:      180,
}

func main() {
	// Default data dir based on platform
	defaultData := getEnv("QUADRA_DATADIR", "")
	if defaultData == "" {
		if runtime.GOOS == "windows" {
			defaultData = "C:\\quadra\\data"
		} else {
			defaultData = "/home/groups/q/qu/quadra/data"
		}
	}

	datadir := flag.String("datadir", defaultData, "Data directory path")
	port := flag.String("port", "3456", "Port to listen on")
	debug := flag.Int("debug", 0, "Debug level (0=off, 1=on)")
	logfile := flag.String("logfile", "", "Access log file path (default: stderr only)")
	publicip := flag.String("public-ip", "", "Public IP to advertise (replaces private LAN IPs in game listings)")
	flag.Parse()

	Config.DataDir, _ = filepath.Abs(*datadir)
	Config.Port = *port
	Config.Debug = *debug
	Config.PublicIP = *publicip

	// env override for debug
	if Config.Debug == 0 && os.Getenv("DEBUG") != "" {
		Config.Debug = 1
	}

	// Initialize access logging
	if err := initLogging(*logfile); err != nil {
		log.Fatalf("Failed to init logging: %v", err)
	}
	defer closeLogging()

	// Initialize data directories
	if err := initDataDir(); err != nil {
		log.Fatalf("Failed to initialize data directory: %v", err)
	}

	// Start HTTP server
	http.HandleFunc("/", requestHandler)
	addr := ":" + Config.Port
	log.Printf("Starting qserv on port %s (data dir: %s)", Config.Port, Config.DataDir)
	printLocalIPs(Config.Port)
	log.Fatal(http.ListenAndServe(addr, nil))
}

// printLocalIPs lists available local IP addresses for client connections
func printLocalIPs(port string) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return
	}
	var ips []string
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			if ipnet, ok := a.(*net.IPNet); ok && ipnet.IP.To4() != nil {
				ips = append(ips, ipnet.IP.String()+":"+port)
			}
		}
	}
	if len(ips) > 0 {
		log.Printf("  Available at: %s", strings.Join(ips, ", "))
	}
}

// getEnv reads env variable, returns default if not set
func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}