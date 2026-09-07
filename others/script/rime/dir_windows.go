//go:build windows
// +build windows

package rime

import (
	"golang.org/x/sys/windows/registry"
	"log"
	"os"
	"path/filepath"
)

// 获取 Windows Rime 配置目录
func getRimeDirForPlatform() string {
	keyPath := `Software\Rime\Weasel`
	valueName := "RimeUserDir"

	// Get from Windows registry
	k, err := registry.OpenKey(registry.CURRENT_USER, keyPath, registry.QUERY_VALUE)
	if err != nil {
		log.Printf("Failed to open registry key: %v\n", err)
		// Fallback to default dir
		return getDefaultWeaselDir()
	}
	defer k.Close()

	rimeUserDir, _, err := k.GetStringValue(valueName)
	if err != nil {
		log.Printf("Failed to read registry value: %v\n", err)
		// Fallback to default dir
		return getDefaultWeaselDir()
	}

	return rimeUserDir
}

func getDefaultWeaselDir() string {
	appData := os.Getenv("APPDATA") // AppData\Roaming
	if appData == "" {
		log.Fatalln("APPDATA environment variable is not set.")
	}
	return filepath.Join(appData, "Rime")
}
