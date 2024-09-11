//go:build linux
// +build linux

package rime

import (
	"log"
	"os/user"
	"path/filepath"
)

func getRimeDirForPlatform() string {
	u, err := user.Current()
	if err != nil {
		log.Fatalln(err)
	}
	return filepath.Join(u.HomeDir, ".config", "rime")
}
