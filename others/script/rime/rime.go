package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"unicode"
)

// 一个词的组成部分
type lemma struct {
	text   string // 汉字
	code   string // 编码
	weight int    // 权重
}

// filterType:
// 1.只匹配原本为全小写的
// 2.仅首字母转为小写 如：Windows XP → windows xP
// 3.全部转为小写
// cutOffType: 1 去除空格 2 去除连字符"-" 3 去除空格及连字符
type rule4EngEntry struct {
	filterType int // 汉字
	cutOffType int // 权重
}

var (
	mark    = "# +_+"      // 词库中的标记符号，表示从这行开始进行检查或排序
	RimeDir = getRimeDir() // Rime 配置目录

	EmojiMapPath = filepath.Join(RimeDir, "others/emoji-map.txt")
	EmojiPath    = filepath.Join(RimeDir, "opencc/emoji.txt")

	HanziPath   = filepath.Join(RimeDir, "cn_dicts/8105.dict.yaml")
	BasePath    = filepath.Join(RimeDir, "cn_dicts/base.dict.yaml")
	ExtPath     = filepath.Join(RimeDir, "cn_dicts/ext.dict.yaml")
	TencentPath = filepath.Join(RimeDir, "cn_dicts/tencent.dict.yaml")
	EnPath      = filepath.Join(RimeDir, "en_dicts/en.dict.yaml")
	EnExtPath   = filepath.Join(RimeDir, "en_dicts/en_ext.dict.yaml")

	rule4En    = rule4EngEntry{1, 3}
	rule4EnExt = rule4EngEntry{2, 3}

	HanziSet   = readToSet(HanziPath)
	BaseSet    = readToSet(BasePath)
	ExtSet     = readToSet(ExtPath)
	TencentSet = readToSet(TencentPath)
	EnSet      = readToSet4Eng(EnPath, rule4En)
	EnExtSet   = readToSet4Eng(EnExtPath, rule4EnExt)

	需要注音TXT   = filepath.Join(RimeDir, "others/script/rime/需要注音.txt")
	错别字TXT    = filepath.Join(RimeDir, "others/script/rime/错别字.txt")
	汉字拼音映射TXT = filepath.Join(RimeDir, "others/script/rime/汉字拼音映射.txt")
)

// 将所有词库读入 set，供检查或排序使用
func readToSet(dictPath string) mapset.Set[string] {
	set := mapset.NewSet[string]()

	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		set.Add(parts[0])
	}

	return set
}

// 将所有词库读入 set，供检查或排序使用
func readToSet4Eng(dictPath string, rule rule4EngEntry) mapset.Set[string] {
	set := mapset.NewSet[string]()

	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		if rule.filterType == 1 && !isLowercase(line) {
			continue
		}
		parts := strings.Split(line, "\t")

		text, code := parts[0], strings.ToLower(parts[1])

		set.Add(getKey4EngSet(text, code, rule))
	}

	return set
}

func getKey4EngSet(text string, code string, rule rule4EngEntry) string {
	if rule.filterType == 2 {
		text = convertFirstLetterToLower(text)
	} else if rule.filterType == 3 {
		text = strings.ToLower(text)
	}

	if rule.cutOffType == 2 || rule.cutOffType == 3 {
		code = modifyText(text, 2)
	}

	return modifyText(text, rule.cutOffType) + code
}

func modifyText(text string, cutOffType int) string {
	switch cutOffType {
	case 1:
		return strings.ReplaceAll(text, " ", "")
	case 2:
		return strings.ReplaceAll(text, "-", "")
	case 3:
		text = strings.ReplaceAll(text, " ", "")
		return strings.ReplaceAll(text, "-", "")
	default:
		return text
	}
}

// 首字母大写的单词，仅将首字母转为小写
func convertFirstLetterToLower(s string) string {
	var builder strings.Builder
	words := strings.Fields(s)
	for _, word := range words {
		if len(word) > 0 && unicode.IsUpper(rune(word[0])) {
			builder.WriteRune(unicode.ToLower(rune(word[0])))
			if len(word) > 1 {
				builder.WriteString(word[1:])
			}
		} else {
			builder.WriteString(word)
		}
		builder.WriteRune(' ')
	}
	result := builder.String()
	return strings.TrimSpace(result)
}

// 检查是否全为小写
func isLowercase(s string) bool {
	for _, r := range s {
		if unicode.IsLetter(r) && !unicode.IsLower(r) {
			return false
		}
	}
	return true
}

// 打印耗时时间
func printlnTimeCost(content string, start time.Time) {
	// fmt.Printf("%s：\t%.2fs\n", content, time.Since(start).Seconds())
	printfTimeCost(content, start)
	fmt.Println()
}

// 打印耗时时间
func printfTimeCost(content string, start time.Time) {
	fmt.Printf("%s：\t%.2fs", content, time.Since(start).Seconds())
}

// slice 是否包含 item
func contains(arr []string, item string) bool {
	for _, x := range arr {
		if item == x {
			return true
		}
	}
	return false
}

// AddWeight  为 ext、tencent 没权重的词条加上权重，有权重的改为 weight
func AddWeight(dictPath string, weight int) {
	// 控制台输出
	printlnTimeCost("加权重\t"+path.Base(dictPath), time.Now())

	// 读取到 lines 数组
	file, err := os.ReadFile(dictPath)
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(file), "\n")

	isMark := false
	for i, line := range lines {
		if !isMark {
			if strings.HasPrefix(line, mark) {
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

	// 写入
	resultString := strings.Join(lines, "\n")
	err = os.WriteFile(dictPath, []byte(resultString), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
