package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

// 同义多音字
var polyphonicWords = []string{
	"谁",
	"血",
	"熟",
	"掴",
	"爪",
	"薄",
	"剥",
	"哟",
	"嚼",
	"忒", // te 不是，tui 和 tei 是
	"密钥",
	"公钥",
	"私钥",
	"甲壳",
	"掉色",
}

// 不检查的词汇
var polyphonicWordsFilter = []string{
	"咀嚼",
	"薄暮", "薄地", "薄海", "薄酒", "薄礼", "薄面", "薄命", "薄情", "薄弱", "薄田", "薄物细故", "薄幸", "薄情", "薄葬", "厌薄", "厚积薄发", "履薄临深", "德薄望轻", "菲薄", "履薄", "孤军薄旅", "薄太后",
	"剥离", "剥夺", "剥削", "剥落", "剥蚀", "剥啄",
	"熟稔", "黄熟",
}

// CheckPolyphone 检查 base、ext 中同义多音字是否有两种读音
// 例如「谁的」应该同时存在 shei de 与 shui de 两种读音
func CheckPolyphone(dictPath string) {
	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 将含有同义多音字的词汇放入，key 为词汇，value 为注音
	// 如果注音数组只有一个，则应该补充其他读音
	m := make(map[string][]string)

	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) != 3 {
			continue
		}
		text, code := parts[0], parts[1]
		if containsPolyphonicWordsFilter(text) {
			continue
		}
		for _, word := range polyphonicWords {
			if strings.Contains(text, word) {
				m[text] = append(m[text], code)
			}
		}
	}

	// 遍历 m，输出单数读音的词汇
	for text, codes := range m {
		if len(codes)%2 != 0 {
			fmt.Println(text)
		}
	}
}

func containsPolyphonicWordsFilter(text string) bool {
	for _, filter := range polyphonicWordsFilter {
		if strings.Contains(text, filter) {
			return true
		}
	}
	return false
}
