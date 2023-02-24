package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"
)

var emojiTXT = "/Users/dvel/Library/Rime/opencc/emoji.txt"
var mappingTXT = "/Users/dvel/Library/Rime/opencc/emoji-map.txt"

type OrderedMap struct {
	keys []string
	m    map[string][]string
}

// CheckEmoji 检查 Emoji
// 检查 emoji-map.txt 格式书写问题
// 检查所有词条是否与 base 词库存在差集
func CheckEmoji() {
	// 控制台输出
	defer printlnTimeCost("检查 Emoji 差集", time.Now())

	// 打开文件
	file, err := os.Open(EmojiPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 将 Emoji 加入 set，为检测差集做准备
	emojiSet := mapset.NewSet[string]()
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		// 过滤空行
		if line == "" {
			continue
		}
		// 过滤注释
		if strings.Contains(line, "#") {
			continue
		}
		// 检查是否包含 Tab
		if strings.Contains(line, "\t") {
			fmt.Println("❌ 此行包含 Tab：", line)
		}
		// 开头结尾无效的空格
		if strings.HasPrefix(line, " ") || strings.HasSuffix(line, " ") {
			fmt.Println("❌ unexpected space:", line)
		}
		parts := strings.Split(line, " ")
		if len(parts) < 2 {
			fmt.Println("❌ invalid line:", line)
		}
		// 加入 emojiSet，顺便用一个 tempSet 查重
		tempSet := mapset.NewSet[string]()
		for _, word := range parts[1:] {
			emojiSet.Add(word)
			if tempSet.Contains(word) {
				fmt.Println("❌ 此行有重复映射：", line)
			} else {
				tempSet.Add(word)
			}
		}
	}

	// 检查 emoji 中的词条是否与 base+sogou+ext 词库存在差集
	for _, word := range emojiSet.Difference(BaseSet).ToSlice() {
		// 去除英文字母
		if match, _ := regexp.MatchString(`[A-Za-z]+`, word); match {
			continue
		}
		// 去除一个字的
		if utf8.RuneCountInString(word) == 1 {
			continue
		}
		fmt.Println("❌ Emoji 差集：", word)
	}
}

// UpdateEmojiTXT 从 emoji-map.txt 生成或更新 emoji.txt
func UpdateEmojiTXT() {
	// 控制台输出
	defer printlnTimeCost("更新 emoji.txt", time.Now())

	// 读取 emoji-map.txt
	mappingFile, err := os.Open(mappingTXT)
	if err != nil {
		log.Fatal(err)
	}
	defer mappingFile.Close()

	om := new(OrderedMap)
	om.keys = make([]string, 0)
	om.m = make(map[string][]string)

	sc := bufio.NewScanner(mappingFile)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") && !strings.Contains(line, "井号") { // #️⃣被判断为以 # 开头了。。。
			continue
		}
		arr := strings.Split(line, " ")
		for _, word := range arr[1:] {
			if !contains(om.keys, word) {
				om.keys = append(om.keys, word)
			}
			om.m[word] = append(om.m[word], arr[0])
		}
	}

	// 写入 emoji.txt
	emojiFile, err := os.OpenFile(emojiTXT, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0666)
	if err != nil {
		log.Fatalln(err)
	}
	defer emojiFile.Close()

	for _, key := range om.keys {
		line := key + "\t" + key + " " + strings.Join(om.m[key], " ") + "\n"
		_, err := emojiFile.WriteString(line)
		if err != nil {
			log.Fatal(err)
		}
	}

	if err := emojiFile.Sync(); err != nil {
		log.Fatal(err)
	}
}
