//go:build darwin
// +build darwin

package rime

import (
	"log"
	"os/user"
	"path/filepath"
	"runtime"
)

// 获取 macOS/Windows Rime 配置目录
func getRimeDir() string {
	var dir string
	switch runtime.GOOS {
	case "darwin": // macOS
		u, err := user.Current()
		if err != nil {
			log.Fatalln(err)
		}
		dir = filepath.Join(u.HomeDir, "Library/Rime")
	// case "windows": // Windows
	// dir = getWeaselDir()
	default:
		log.Fatalf("Unsupported OS: %s so far", runtime.GOOS)
	}

	return dir
}
