//go:build darwin
// +build darwin

package rime

import (
	"log"
	"os/user"
	"path/filepath"
)

// 获取 macOS Rime 配置目录
func getRimeDirForPlatform() string {
	u, err := user.Current()
	if err != nil {
		log.Fatalln(err)
	}
	return filepath.Join(u.HomeDir, "Library/Rime")
}
