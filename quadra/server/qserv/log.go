package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

var (
	accessLogger *log.Logger
	logFile      *os.File
)

// initLogging sets up request access logging to stderr and optionally a file
func initLogging(logPath string) error {
	if logPath == "" {
		accessLogger = log.New(os.Stderr, "", log.LstdFlags)
		return nil
	}

	f, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("cannot open log file %s: %v", logPath, err)
	}
	logFile = f

	// Write to both stderr and file
	multi := io.MultiWriter(os.Stderr, f)
	accessLogger = log.New(multi, "", log.LstdFlags)
	accessLogger.Printf("--- qserv log started ---")
	return nil
}

// closeLogging closes the log file if open
func closeLogging() {
	if logFile != nil {
		logFile.Close()
	}
}

// logRequest logs an incoming HTTP request
func logRequest(clientIP, cmd string) {
	accessLogger.Printf("[REQ] %-15s %s", clientIP, cmd)
}

// logResponse logs the result of a command
func logResponse(clientIP, cmd, result string) {
	accessLogger.Printf("[RES] %-15s %-12s %s", clientIP, cmd, result)
}

// logError logs an error with optional details
func logError(clientIP, cmd, detail string) {
	accessLogger.Printf("[ERR] %-15s %-12s %s", clientIP, cmd, detail)
}

// logDataOp logs a data write operation
func logDataOp(clientIP, op, path string) {
	accessLogger.Printf("[DATA] %-15s %-8s %s", clientIP, op, path)
}

// clientIP extracts the IP from RemoteAddr
func clientIP(r *http.Request) string {
	ip := r.RemoteAddr
	for i := len(ip) - 1; i >= 0; i-- {
		if ip[i] == ':' {
			return ip[:i]
		}
	}
	return ip
}

// accessLog is a middleware-like wrapper that logs start and end of requests
func accessLog(r *http.Request, cmd string) func(result string) {
	ip := clientIP(r)
	t := time.Now()
	logRequest(ip, cmd)
	return func(result string) {
		elapsed := time.Since(t)
		msg := result
		if elapsed > 100*time.Millisecond {
			msg = fmt.Sprintf("%s (%dms)", result, elapsed.Milliseconds())
		}
		logResponse(ip, cmd, msg)
	}
}
