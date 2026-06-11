package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"sync"
	"time"
)

var (
	cleanupRegistry = make(map[string]func())
	mu             sync.Mutex
)

// initDataDir 初始化資料目錄
func initDataDir() error {
	dirs := []string{
		filepath.Join(Config.DataDir, "games"),
		filepath.Join(Config.DataDir, "scores"),
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create dir %s: %v", dir, err)
		}
	}

	// 註冊清理函式
	cleanupRegistry["games"] = cleanupGames
	cleanupRegistry["scores"] = cleanupScores
	return nil
}

// cleanup 執行所有已註冊的清理函式
func cleanup() {
	mu.Lock()
	defer mu.Unlock()

	for name, cleaner := range cleanupRegistry {
		cleaner()
		delete(cleanupRegistry, name)
	}
}

// cleanupGames 清理過期遊戲
func cleanupGames() {
	gamesDir := filepath.Join(Config.DataDir, "games")
	files, err := os.ReadDir(gamesDir)
	if err != nil {
		if Config.Debug >= 3 {
			log.Printf("failed to read games dir: %v", err)
		}
		return
	}

	now := time.Now().Unix()
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		
		filePath := filepath.Join(gamesDir, file.Name())
		stat, err := os.Stat(filePath)
		if err != nil {
			continue
		}
		
		if now-stat.ModTime().Unix() >= int64(Config.Timeout) {
			if Config.Debug >= 3 {
				log.Printf("deleting expired game: %s", file.Name())
			}
			os.Remove(filePath)
		}
	}
	if Config.Debug >= 3 {
		log.Println("cleaned up games")
	}
}

// cleanupScores 清理過期分數（保留最近 100 筆）
func cleanupScores() {
	scoresDir := filepath.Join(Config.DataDir, "scores")
	files, err := os.ReadDir(scoresDir)
	if err != nil {
		if Config.Debug >= 3 {
			log.Printf("failed to read scores dir: %v", err)
		}
		return
	}

	// 收集所有分數檔案
	scores := make([]os.DirEntry, 0)
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

	// 刪除多餘分數
	if len(scores) > Config.ScoresToKeep {
		old := scores[Config.ScoresToKeep:]
		for _, file := range old {
			filePath := filepath.Join(scoresDir, file.Name())
			if Config.Debug >= 2 {
				log.Printf("deleting old score: %s", file.Name())
			}
			os.Remove(filePath)
		}
	}
	if Config.Debug >= 3 {
		log.Println("cleaned up scores")
	}
}