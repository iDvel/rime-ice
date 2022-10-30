package rime

import (
	"log"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

func AddWeight(dictPath string, weight int) {
	// 控制台输出
	printlnTimeCost("加权重\t"+path.Base(dictPath), time.Now())

	// 读取文件到 lines 数组
	file, err := os.ReadFile(dictPath)
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(file), "\n")

	// 逐行遍历，加上 weight
	isMark := false
	for i, line := range lines {
		if !isMark {
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		// 过滤空行
		if line == "" {
			continue
		}
		// 修改权重为传入的 weight，没有就加上
		parts := strings.Split(line, "\t")
		_, err := strconv.Atoi(parts[len(parts)-1])
		if err != nil {
			lines[i] = line + "\t" + strconv.Itoa(weight)
		} else {
			lines[i] = strings.Join(parts[:len(parts)-1], "\t") + "\t" + strconv.Itoa(weight)
		}
	}

	// 重新写入
	resultString := strings.Join(lines, "\n")
	err = os.WriteFile(dictPath, []byte(resultString), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
