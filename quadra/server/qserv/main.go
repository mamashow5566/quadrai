package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
)

// Config holds runtime configuration
var Config = struct {
	DataDir      string
	Debug        int
	Port         string
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
	flag.Parse()

	Config.DataDir, _ = filepath.Abs(*datadir)
	Config.Port = *port
	Config.Debug = *debug

	// env override for debug
	if Config.Debug == 0 && os.Getenv("DEBUG") != "" {
		Config.Debug = 1
	}

	// Initialize data directories
	if err := initDataDir(); err != nil {
		log.Fatalf("Failed to initialize data directory: %v", err)
	}

	// Start HTTP server
	http.HandleFunc("/", requestHandler)
	addr := ":" + Config.Port
	log.Printf("Starting qserv on %s (data dir: %s)", addr, Config.DataDir)
	log.Fatal(http.ListenAndServe(addr, nil))
}

// getEnv reads env variable, returns default if not set
func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}