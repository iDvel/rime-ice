package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"
)

var (
	specialWords = mapset.NewSet[string]() // 特殊词汇列表，不进行任何检查

	polyphoneWords = mapset.NewSet[string]() // 需要注音的字词

	wrongWords       = mapset.NewSet[string]() // 异形词、错别字
	wrongWordsFilter = mapset.NewSet[string]() // 过滤一部分，包含错别字但不是错别字，如「作爱」是错的，但「叫作爱」是对的

	hanPinyin       = make(map[string][]string) // 汉字拼音映射，用于检查注音是否正确
	hanPinyinFilter = mapset.NewSet[string]()   // 过滤一部分，比如「深厉浅揭qi」只在这个词中念qi，并不是错误。
)

// 初始化特殊词汇列表、需要注音列表、错别字列表、拼音列表
func init() {
	// 特殊词汇列表，不进行任何检查
	specialWords.Add("狄尔斯–阿尔德反应")
	specialWords.Add("特里斯坦–达库尼亚")
	specialWords.Add("特里斯坦–达库尼亚群岛")
	specialWords.Add("茱莉亚·路易斯-德瑞弗斯")
	specialWords.Add("科科斯（基林）群岛")
	specialWords.Add("刚果（金）")
	specialWords.Add("刚果（布）")
	specialWords.Add("赛博朋克：边缘行者")
	specialWords.Add("赛博朋克：边缘跑手")
	specialWords.Add("赛博朋克：命运之轮")
	specialWords.Add("哈勃–勒梅特定律")

	// 需要注音的列表
	file1, err := os.Open(需要注音TXT)
	if err != nil {
		log.Fatalln(err)
	}
	defer file1.Close()
	sc := bufio.NewScanner(file1)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") || line == "" {
			continue
		}
		polyphoneWords.Add(line)
	}

	// 错别字的两个列表： wrongWords wrongWordsFilter
	file2, err := os.Open(错别字TXT)
	if err != nil {
		log.Fatalln(err)
	}
	defer file2.Close()
	sc = bufio.NewScanner(file2)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "# -_-") {
			isMark = true
			continue
		}
		if strings.HasPrefix(line, "#") || line == "" {
			continue
		}
		if !isMark {
			wrongWords.Add(line)
		} else {
			wrongWordsFilter.Add(line)
		}
	}

	// 汉字拼音映射 hanPinyin hanPinyinFilter
	// 将所有读音读入 hanPinyin
	file3, err := os.Open(HanziPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file3.Close()
	isMark = false
	sc = bufio.NewScanner(file3)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		text, code := parts[0], parts[1]
		hanPinyin[text] = append(hanPinyin[text], code)
	}
	// 给 hanPinyin 补充不再字表的读音，和过滤列表 hanPinyinFilter
	file4, err := os.Open(汉字拼音映射TXT)
	if err != nil {
		log.Fatalln(err)
	}
	defer file4.Close()
	sc = bufio.NewScanner(file4)
	isMark = false
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") && !strings.HasPrefix(line, "# -_-") || line == "" {
			continue
		}
		if strings.HasPrefix(line, "# -_-") {
			isMark = true
			continue
		}
		if !isMark {
			parts := strings.Split(line, " ")
			key := parts[0]
			values := parts[1:]
			hanPinyin[key] = append(hanPinyin[key], values...)
		} else {
			hanPinyinFilter.Add(line)
		}
	}
}

// Check 对传入的词库文件进行检查
// dictPath: 词库文件路径
// _type: 词库类型 1 只有汉字 2 汉字+注音 3 汉字+注音+权重 4 汉字+权重
func Check(dictPath string, _type int) {
	// 控制台输出
	defer printlnTimeCost("检查 "+path.Base(dictPath), time.Now())

	// 打开文件
	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 开始检查！
	lineNumber := 0
	isMark := false
	sc := bufio.NewScanner(file)
	var wg sync.WaitGroup
	for sc.Scan() {
		lineNumber++
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		wg.Add(1)
		go checkLine(dictPath, _type, line, lineNumber, &wg)
	}

	if err := sc.Err(); err != nil {
		log.Fatalln(err)
	}

	wg.Wait()
}

// 检查一行
func checkLine(dictPath string, _type int, line string, lineNumber int, wg *sync.WaitGroup) {
	defer wg.Done()

	// 忽略注释，base 中有很多被注释了的词汇，暂时没有删除
	if strings.HasPrefix(line, "#") {
		// 注释以 '#' 开头，但不是以 '# '开头（强迫症晚期）
		if !strings.HasPrefix(line, "# ") {
			fmt.Println("has # but not #␣", line)
		}
		return
	}

	// 有空行
	if strings.TrimSpace(line) == "" {
		fmt.Println("empty line", line)
	}

	// +---------------------------------------------------------------
	// | 开始检查分割后的内容，分割为： 词汇text 编码code 权重weight
	// +---------------------------------------------------------------
	parts := strings.Split(line, "\t")
	var text, code, weight string
	switch {
	case _type == 1 && len(parts) == 1: // 一列，【汉字】
		text = parts[0]
	case _type == 2 && len(parts) == 2: // 两列，【汉字+注音】
		text, code = parts[0], parts[1]
	case _type == 3 && len(parts) == 3: // 三列，【汉字+注音+权重】
		text, code, weight = parts[0], parts[1], parts[2]
	case _type == 4 && len(parts) == 2: // 两列，【汉字+权重】
		text, weight = parts[0], parts[1]
	default:
		log.Fatalln("❌ 分割错误：", lineNumber, line)
	}

	// weight 应该是纯数字
	if weight != "" {
		_, err := strconv.Atoi(weight)
		if err != nil {
			fmt.Println("❌ weight 非数字：", line)
		}
	}

	// text 和 weight 不应该含有空格
	if strings.Contains(text, " ") || strings.Contains(weight, " ") {
		fmt.Println("❌ text 和 weight 含有空格：", line)
	}

	// code 前后不应该有空格
	if strings.HasPrefix(code, " ") || strings.HasSuffix(code, " ") {
		fmt.Println("❌ code 前后有空格：", line)
	}

	// code 不应该有非小写字母
	for _, r := range code {
		if string(r) != " " && !unicode.IsLower(r) {
			fmt.Println("❌ code 含有非小写字母：", line)
			break
		}
	}

	// 过滤特殊词条
	if specialWords.Contains(text) {
		return
	}

	// text 不应该有非汉字内容，除了间隔号 ·
	for _, c := range text {
		if string(c) != "·" && !unicode.Is(unicode.Han, c) {
			fmt.Println("❌ text 含有非汉字内容：", line)
			break
		}
	}

	// 除了字表，其他词库不应该含有单个的汉字
	if dictPath != HanziPath && utf8.RuneCountInString(text) == 1 {
		fmt.Println("❌ 意外的单个汉字：", line)
	}

	// 除了 base，其他词库不应该含有两个字的词汇
	if dictPath != BasePath && utf8.RuneCountInString(text) == 2 {
		fmt.Println("❌ 意外的两字词：", line)
	}

	// 汉字个数应该和拼音个数相等
	if code != "" {
		codeCount := len(strings.Split(code, " "))
		textCount := utf8.RuneCountInString(text)
		if strings.Contains(text, "·") {
			textCount -= strings.Count(text, "·")
		}
		if strings.HasPrefix(text, "# ") {
			textCount -= 2
		}
		if textCount != codeCount {
			fmt.Println("❌ 汉字个数 != 拼音个数：", line)
		}
	}

	// +---------------------------------------------------------------
	// | 其他检查
	// +---------------------------------------------------------------

	// 需要注音但没有注音的字
	if dictPath == TencentPath {
		for _, word := range polyphoneWords.ToSlice() {
			if strings.Contains(text, word) {
				fmt.Println("❌ 需要注音：", line)
			}
		}
	}

	// 检查拼写错误，如「赞zan」写成了zna；顺便检查是否存在字表中没有注音的字
	if dictPath != HanziPath && (_type == 2 || _type == 3) && !hanPinyinFilter.Contains(text) {
		// 把汉字和拼音弄成一一对应关系，「拼音:pin yin」→「拼:pin」「音:yin」
		textWithoutDian := strings.ReplaceAll(text, "·", "") // 去掉间隔号
		pinyins := strings.Split(code, " ")
		i := 0
		for _, zi := range textWithoutDian {
			if !contains(hanPinyin[string(zi)], pinyins[i]) {
				fmt.Printf("❌ 注音错误 or 字表未包含的汉字及注音: %s - %s.+%s\n", line, string(zi), pinyins[i])
			}
			i++
		}
	}

	// 错别字检查，最耗时的检查
	if dictPath != HanziPath && !wrongWordsFilter.Contains(text) {
		wrongWords.Each(func(wrongWord string) bool {
			if strings.HasPrefix(wrongWord, "=") {
				wrongWord = strings.TrimLeft(wrongWord, "= ")
				if text == wrongWord {
					fmt.Printf("❌ 错别字: %s = %s\n", text, wrongWord)
					return true
				}
			} else if strings.Contains(text, wrongWord) {
				fmt.Printf("❌ 错别字: %s - %s\n", text, wrongWord)
				return true
			}
			return false
		})
	}
}
