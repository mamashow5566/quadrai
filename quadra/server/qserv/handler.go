package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

var (
	safeRegex = regexp.MustCompile(`^[-\@\w.:]+$`)
)

// sanitizeGameAddr replaces characters invalid in filenames on Windows
func sanitizeGameAddr(addr string) string {
	return strings.ReplaceAll(addr, ":", "_")
}

// unsanitizeGameAddr restores the original IP:PORT format
func unsanitizeGameAddr(addr string) string {
	return strings.ReplaceAll(addr, "_", ":")
}

// requestHandler handles all HTTP requests
func requestHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Set Content-Type
	w.Header().Set("Content-Type", "text/plain")

	// Parse data parameter
	if err := r.ParseForm(); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

data := r.PostFormValue("data")
	lines := strings.Split(data, "\n")
	if len(lines) == 0 {
		defaultResponse(w, r)
		return
	}

	cmd := lines[0]
	params := make(map[string]interface{})
	if len(lines) > 1 {
		for _, line := range lines[1:] {
			if line == "" {
				continue
			}
			parts := strings.SplitN(line, " ", 2)
			if len(parts) == 2 {
				setParam(params, parts[0], parts[1])
			}
		}
	}

	// Execute tweak preprocessing
	tweak(r, params)

	// Start access log
	done := accessLog(r, cmd)

	// Command dispatch
	switch cmd {
	case "postgame":
		doPostGame(w, r, params)
		done("ok")
		return
	case "deletegame":
		doDeleteGame(w, r, params)
		done("ok")
		return
	case "postdemo":
		doPostDemo(w, r, params)
		done("ok")
		return
	case "gethighscores":
		doGetHighScores(w, r, params)
		done("ok")
		return
	case "getgames":
		doGetGames(w, r, params)
		done("ok")
		return
	default:
		defaultResponse(w, r)
		done("unknown")
		return
	}
}

// doPostGame handles game data upload
func doPostGame(w http.ResponseWriter, r *http.Request, params map[string]interface{}) {
	addr, ok := getParam(params, "info/remoteaddr")
	if !ok {
		fmt.Fprint(w, "Bad data")
		return
	}
	port, ok := getParam(params, "port")
	if !ok {
		fmt.Fprint(w, "Bad data")
		return
	}

	gameAddr := fmt.Sprintf("%s:%s", addr, port)
	if !isSafePath(gameAddr) {
		fmt.Fprint(w, "Bad data")
		return
	}
	safeAddr := sanitizeGameAddr(gameAddr)

	// auto-set lastupdate
	setParam(params, "info/lastupdate", fmt.Sprintf("%d", time.Now().Unix()))

	gamesDir := filepath.Join(Config.DataDir, "games")
	gameFile := filepath.Join(gamesDir, safeAddr)

	// check existence BEFORE writing (matching Perl -e logic)
	existed := false
	if _, err := os.Stat(gameFile); err == nil {
		existed = true
	}

	if err := SaveAsPerlDumper(gameFile, params); err != nil {
		if Config.Debug >= 1 {
			log.Printf("Failed to save game data: %v", err)
		}
		fmt.Fprint(w, "Bad data")
		return
	}

	if existed {
		fmt.Fprint(w, "Game updated")
	} else {
		fmt.Fprint(w, "Game added")
	}
}

// doDeleteGame 處理遊戲刪除
func doDeleteGame(w http.ResponseWriter, r *http.Request, params map[string]interface{}) {
	addr, ok := getParam(params, "info/remoteaddr")
	if !ok {
		fmt.Fprint(w, "Game not found")
		return
	}
	port, ok := getParam(params, "port")
	if !ok {
		fmt.Fprint(w, "Game not found")
		return
	}
	
	// 處理連續點
	gameAddr := fmt.Sprintf("%s:%s", addr, port)
	gameAddr = regexp.MustCompile(`\.{2,}`).ReplaceAllString(gameAddr, ".")
	if !isSafePath(gameAddr) {
		fmt.Fprint(w, "Game not found")
		return
	}

	gamesDir := filepath.Join(Config.DataDir, "games")
	gameFile := filepath.Join(gamesDir, sanitizeGameAddr(gameAddr))
	
	if err := os.Remove(gameFile); err != nil {
		if os.IsNotExist(err) {
			fmt.Fprint(w, "Game not found")
		} else {
			if Config.Debug >= 1 {
				log.Printf("Failed to delete game: %v", err)
			}
			fmt.Fprint(w, "Game not found")
		}
		return
	}
	fmt.Fprint(w, "Game deleted")
}

// doPostDemo handles score upload
func doPostDemo(w http.ResponseWriter, r *http.Request, params map[string]interface{}) {
	score, ok := getParam(params, "score")
	if !ok {
		fmt.Fprint(w, "Bad data")
		return
	}

	scoreStr := fmt.Sprintf("%v", score)
	if _, err := strconv.Atoi(scoreStr); err != nil {
		fmt.Fprint(w, "Bad data")
		return
	}

	scoresDir := filepath.Join(Config.DataDir, "scores")
	scoreFile := filepath.Join(scoresDir, scoreStr)

	if err := SaveAsPerlDumper(scoreFile, params); err != nil {
		if Config.Debug >= 1 {
			log.Printf("Failed to save score data: %v", err)
		}
		fmt.Fprint(w, "Bad data")
		return
	}

	// auto-return high scores
	doGetHighScores(w, r, params)
}

// doGetHighScores 取得分數排行
func doGetHighScores(w http.ResponseWriter, r *http.Request, params map[string]interface{}) {
	scoresDir := filepath.Join(Config.DataDir, "scores")
	files, err := os.ReadDir(scoresDir)
	if err != nil {
		if Config.Debug >= 1 {
			log.Printf("Failed to read scores dir: %v", err)
		}
		fmt.Fprint(w, "Bad data")
		return
	}
	
	// 收集所有分數檔案
	scores := []os.DirEntry{}
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		if _, err := strconv.Atoi(file.Name()); err == nil {
			scores = append(scores, file)
		}
	}
	
	// 按分數降序排列
	sort.Slice(scores, func(i, j int) bool {
		return scores[i].Name() > scores[j].Name()
	})
	
	// 限制輸出筆數
	num := Config.ScoresToKeep
	if n, ok := getParam(params, "num"); ok {
		if nNum, err := strconv.Atoi(fmt.Sprintf("%v", n)); err == nil {
			num = nNum
		}
	}
	if len(scores) > num {
		scores = scores[:num]
	}
	
	// 開始輸出
	fmt.Fprint(w, "Ok\n")
	var highIndex int
	for _, file := range scores {
		var scoreData map[string]interface{}
		filePath := filepath.Join(scoresDir, file.Name())
		if err := LoadPerlDumper(filePath, &scoreData); err != nil {
			continue
		}
		
		// 輸出格式：highXXX/key value
		prefix := fmt.Sprintf("high%03d", highIndex)
		highIndex++
		outputParams(w, prefix, scoreData)
	}
}

// doGetGames 取得遊戲列表
func doGetGames(w http.ResponseWriter, r *http.Request, params map[string]interface{}) {
	gamesDir := filepath.Join(Config.DataDir, "games")
	files, err := os.ReadDir(gamesDir)
	if err != nil {
		if Config.Debug >= 1 {
			log.Printf("Failed to read games dir: %v", err)
		}
		fmt.Fprint(w, "Bad data")
		return
	}
	
	// 收集遊戲資料
	games := make(map[string]map[string]interface{})
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		if !isSafePath(file.Name()) {
			continue
		}
		
		filePath := filepath.Join(gamesDir, file.Name())
		var gameData map[string]interface{}
		if err := LoadPerlDumper(filePath, &gameData); err != nil {
			continue
		}
		games[file.Name()] = gameData
	}
	
	// cleanup expired games
	mu.Lock()
	defer mu.Unlock()
	delete(cleanupRegistry, "games")

	fmt.Fprint(w, "Current games\n")
	var keys []string
	for k := range games {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	
	sent := make(map[string]bool)
	for _, key := range keys {
		game := games[key]
		// version-specific logic
		version, _ := getParam(game, "info/quadra_version")
		qsnoop, _ := getParam(game, "info/qsnoop_version")
		
		// unsanitize for output (Windows-safe filename -> IP:PORT)
		origKey := unsanitizeGameAddr(key)
		
		var displayKey string
		if fmt.Sprintf("%v", version) == "1.1.2" {
			delete(game, "players")
			displayKey = origKey
		} else if version == nil && qsnoop == nil {
			displayKey = strings.Split(origKey, ":")[0]
		} else {
			displayKey = origKey
		}
		
		if !sent[displayKey] {
			outputParams(w, displayKey, game)
			sent[displayKey] = true
		}
	}
}

// outputParams 遞迴輸出參數
func outputParams(w io.Writer, prefix string, data map[string]interface{}) {
	keys := make([]string, 0, len(data))
	for k := range data {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	
	for _, key := range keys {
		value := data[key]
		switch v := value.(type) {
		case map[string]interface{}:
			outputParams(w, fmt.Sprintf("%s/%s", prefix, key), v)
		default:
			fmt.Fprintf(w, "%s/%s %v\n", prefix, key, v)
		}
	}
}

// tweak sets remoteaddr and normalizes port
func tweak(r *http.Request, params map[string]interface{}) {
	// Extract client IP from RemoteAddr
	ip := r.RemoteAddr
	if colon := strings.LastIndex(ip, ":"); colon != -1 {
		ip = ip[:colon]
	}
	// Strip IPv6 brackets: [::1] -> ::1
	ip = strings.TrimPrefix(ip, "[")
	ip = strings.TrimSuffix(ip, "]")
	setParam(params, "info/remoteaddr", ip)
	
	// 處理 port
	port := "3456" // 預設值
	if p, ok := getParam(params, "port"); ok {
		port = fmt.Sprintf("%v", p)
		port = regexp.MustCompile(`[^0-9]`).ReplaceAllString(port, "")
		if port == "" {
			port = "3456"
		} else {
			if pNum, err := strconv.Atoi(port); err == nil && pNum > 65535 {
				port = "3456"
			}
		}
	}
	setParam(params, "port", port)
}

// defaultResponse 未知命令的預設回應
func defaultResponse(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprintf(w, "Hi, I'm the NEW Quadra game server.\nYou should use Quadra to talk to me :).\n")
}

// setParam creates nested map structure from slash-separated keys
func setParam(params map[string]interface{}, key, value string) {
	keys := strings.Split(key, "/")
	m := params
	
	for _, k := range keys[:len(keys)-1] {
		if _, ok := m[k]; !ok {
			m[k] = make(map[string]interface{})
		}
		m = m[k].(map[string]interface{})
	}
	m[keys[len(keys)-1]] = value
}

// getParam retrieves value from nested map using slash-separated keys
func getParam(params map[string]interface{}, key string) (interface{}, bool) {
	keys := strings.Split(key, "/")
	m := params
	
	for _, k := range keys[:len(keys)-1] {
		if val, ok := m[k]; ok {
			m = val.(map[string]interface{})
		} else {
			return nil, false
		}
	}
	val, ok := m[keys[len(keys)-1]]
	return val, ok
}