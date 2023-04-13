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

// CheckAndGenerateEmoji
// 检查 emoji-map.txt 是否合法，检查中文映射是否存在于 base 词库中
// 生成 Rime 格式的 emoji.txt
func CheckAndGenerateEmoji() {
	// 控制台输出
	defer printlnTimeCost("检查、更新 Emoji", time.Now())

	checkEmoji()
	generateEmoji()
}

// 检查 emoji-map.txt 是否合法，检查中文映射是否存在于 base 词库中
func checkEmoji() {
	// 打开文件
	file, err := os.Open(EmojiMapPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	//  将 Emoji 加入一个 set，为检测差集做准备
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
		// 检查：是否包含 Tab
		if strings.Contains(line, "\t") {
			fmt.Println("❌ contains Tab：", line)
			continue
		}
		// 检查：开头结尾无效的空格
		if strings.HasPrefix(line, " ") || strings.HasSuffix(line, " ") {
			fmt.Println("❌ unexpected space：", line)
			continue
		}
		// 开始分割
		parts := strings.Split(line, " ")
		if len(parts) < 2 {
			fmt.Println("❌ invalid line：", line)
			continue
		}
		// 加入 emojiSet，顺便用一个 tempSet 查重
		tempSet := mapset.NewSet[string]()
		for _, text := range parts[1:] {
			emojiSet.Add(text)
			if tempSet.Contains(text) {
				fmt.Println("❌ duplicate mapping：", text)
			} else {
				tempSet.Add(text)
			}
		}
	}

	if err := sc.Err(); err != nil {
		log.Fatalln(err)
	}

	// 检查： emoji-map.txt 中的映射是否存在于 base 词库中，有差集即不存在
	for _, text := range emojiSet.Difference(BaseSet).ToSlice() {
		// 不检查英文
		if match, _ := regexp.MatchString(`[a-zA-Z]`, text); match {
			continue
		}
		// 不检查 1 个字的
		if utf8.RuneCountInString(text) == 1 {
			continue
		}
		fmt.Println("❌ Emoji 与 base 的差集：", text)
	}
}

// 从 emoji-map.txt 生成或更新 emoji.txt
func generateEmoji() {
	// 打开文件
	file, err := os.Open(EmojiMapPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 模拟有序字典
	OmKeys := make([]string, 0)
	OmMap := make(map[string][]string)

	// 将映射读取到字典里
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") && !strings.Contains(line, "井号") { // 井号的 Emoji 被判断为以 # 开头了。。。
			continue
		}
		parts := strings.Split(line, " ")
		for _, text := range parts[1:] {
			if !contains(OmKeys, text) {
				OmKeys = append(OmKeys, text)
			}
			OmMap[text] = append(OmMap[text], parts[0])
		}
	}

	if err := sc.Err(); err != nil {
		log.Fatalln(err)
	}

	// 写入 emoji.txt
	file, err = os.OpenFile(EmojiPath, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	for _, key := range OmKeys {
		line := key + "\t" + key + " " + strings.Join(OmMap[key], " ") + "\n"
		_, err := file.WriteString(line)
		if err != nil {
			log.Fatalln(err)
		}
	}

	if err := file.Sync(); err != nil {
		log.Fatalln(err)
	}
}
