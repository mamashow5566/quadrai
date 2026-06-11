package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

var (
	dumperMu sync.Mutex
)

// LoadPerlDumper reads a Perl Data::Dumper file into dest
func LoadPerlDumper(filePath string, dest interface{}) error {
	dumperMu.Lock()
	defer dumperMu.Unlock()

	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %v", err)
	}
	
	content := string(data)
	// Strip Perl variable declaration
	content = strings.TrimPrefix(content, "$VAR1 = ")
	// Remove trailing semicolon
	content = strings.TrimSuffix(content, ";")
	// Remove trailing newline after last }
	content = strings.TrimSpace(content)
	// Convert Perl => to JSON :
	content = strings.ReplaceAll(content, "=>", ":")
	// Convert Perl single-quoted strings to JSON double-quoted
	// Simple approach: match 'key' or 'value' patterns
	content = perlQuotesToJSON(content)
	// Remove trailing commas (invalid in JSON, Perl Dumper adds them)
	content = removeTrailingCommas(content)

	return json.Unmarshal([]byte(content), dest)
}

// removeTrailingCommas strips commas before } and ] 
func removeTrailingCommas(s string) string {
	s = strings.ReplaceAll(s, ", }", " }")
	s = strings.ReplaceAll(s, ",}", "}")
	s = strings.ReplaceAll(s, ","+string(rune(10))+"}", string(rune(10))+"}")
	s = strings.ReplaceAll(s, ","+string(rune(10))+"  }", string(rune(10))+"  }")
	return s
}

// perlQuotesToJSON converts Perl single-quoted strings to JSON double-quoted
// Handles: 'simple string' -> "simple string"
// Does NOT handle strings with embedded single quotes yet (production TODO)
func perlQuotesToJSON(s string) string {
	// Replace single quotes used as string delimiters with double quotes
	var result strings.Builder
	inString := false
	for i := 0; i < len(s); i++ {
		ch := s[i]
		if ch == '\'' {
			if !inString {
				inString = true
				result.WriteByte('"')
			} else {
				// Check if next char is end of key/value (space, comma, newline, }, etc.)
				inString = false
				result.WriteByte('"')
			}
		} else {
			result.WriteByte(ch)
		}
	}
	return result.String()
}

// SaveAsPerlDumper writes data as Perl Dumper format to destPath atomically
func SaveAsPerlDumper(destPath string, data interface{}) error {
	dumperMu.Lock()
	defer dumperMu.Unlock()

	tmpFile := filepath.Join(os.TempDir(), fmt.Sprintf("qserv_%d_%d.tmp", os.Getpid(), rand.Intn(100000)))

	var buf bytes.Buffer
	buf.WriteString("$VAR1 = {\n")
	writeDumperMap(&buf, data.(map[string]interface{}), 1)
	buf.WriteString("};")

	if err := os.WriteFile(tmpFile, buf.Bytes(), 0644); err != nil {
		return fmt.Errorf("failed to write temp file: %v", err)
	}

	if err := os.Rename(tmpFile, destPath); err != nil {
		os.Remove(tmpFile)
		return fmt.Errorf("failed to rename temp file: %v", err)
	}
	return nil
}

// writeDumperMap 遞迴寫入 map 資料（Perl Dumper 格式）
func writeDumperMap(w io.Writer, data map[string]interface{}, indent int) {
	keys := make([]string, 0, len(data))
	for k := range data {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	
	for _, key := range keys {
		value := data[key]
		for i := 0; i < indent; i++ {
			fmt.Fprint(w, "  ")
		}
		fmt.Fprintf(w, "'%s' => ", key)
		
		switch v := value.(type) {
		case map[string]interface{}:
			fmt.Fprintln(w, "{")
			writeDumperMap(w, v, indent+1)
			for i := 0; i < indent; i++ {
				fmt.Fprint(w, "  ")
			}
			fmt.Fprint(w, "}")
		case string:
			fmt.Fprintf(w, "'%s'", v)
		default:
			fmt.Fprintf(w, "%v", v)
		}
		fmt.Fprintln(w, ",")	}
}

// Helper: 簡單檢查路徑安全性
func isSafePath(input string) bool {
	return safeRegex.MatchString(input)
}