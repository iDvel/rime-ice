package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	mapset "github.com/deckarep/golang-set/v2"
)

var specialWords = mapset.NewSet[string]()   // 特殊词汇列表，不进行任何检查
var polyphoneWords = mapset.NewSet[string]() // 需要注音的多音字列表
var wrongWords = mapset.NewSet[string]()     // 异形词、错别字列表
var filterWords = mapset.NewSet[string]()    // 与异形词列表同时使用，过滤掉，一般是包含异形词但不是异形词的，比如「作爱」是错的，但「叫作爱」是正确的。
var hanPinyinMap = make(map[string][]string) // 汉字拼音映射map，用于检查注音是否正确
var filterPinyins = mapset.NewSet[string]()  // 与汉字拼音映射map同时使用，过滤掉，比如「深厉浅揭qi」只在这个词中念qi，并不是错误。

// 初始化特殊词汇列表、多音字列表、异形词列表、汉字拼音映射
func init() {
	// 特殊词汇列表 specialWords，不进行任何检查
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

	// 需要注音的多音字列表 polyphoneWords
	file, err := os.Open("rime/多音字.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") {
			continue
		}
		polyphoneWords.Add(line)
	}

	// 异形词的两个列表 wrongWords filterWords
	file, err = os.Open("rime/异形词.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	sc = bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()

		if strings.Contains(line, "# -_-") {
			isMark = true
			continue
		}

		if !isMark {
			wrongWords.Add(line)
		} else {
			filterWords.Add(line)
		}
	}

	// 汉字拼音映射的 map
	// 字表的所有读音： hanPinyinMap
	file, err = os.Open(HanziPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	isMark = false
	sc = bufio.NewScanner(file)
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
		hanPinyinMap[text] = append(hanPinyinMap[text], code)
	}
	// 给 hanPinyinMap 补充不在字表的读音，和过滤列表 filterPinyins
	file, err = os.Open("rime/汉字拼音映射.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	sc = bufio.NewScanner(file)
	isMark = false
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "#") && !strings.Contains(line, "# -_-") || line == "" {
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
			hanPinyinMap[key] = append(hanPinyinMap[key], values...)
		} else {
			filterPinyins.Add(line)
		}
	}
}

// Check 对传入的词库文件进行检查
func Check(dictPath string, flag int) {
	// 控制台输出
	defer printlnTimeCost("检查 "+path.Base(dictPath), time.Now())

	// 打开文件
	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 开始检查！
	lineNumber := 0
	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		lineNumber++
		line := sc.Text()
		if !isMark {
			if line == mark {
				isMark = true
			}
			continue
		}

		// 忽略注释，base 里有很多被注释了的词汇，暂时没有删除
		if strings.HasPrefix(line, "#") {
			continue
		}

		// 注释以"#"开头，但不是以"# "开头（没有空格）（强迫症晚期）
		if strings.HasPrefix(line, "#") && !strings.HasPrefix(line, "# ") {
			fmt.Println("has # but not #␣", line)
		}

		// 是否有空行
		if strings.TrimSpace(line) == "" {
			fmt.Println("空行，行号：", lineNumber)
		}

		// 开头结尾是否有空字符
		if line != strings.TrimSpace(line) {
			fmt.Printf("开头或结尾有空格：%q\n", line)
		}

		// +---------------------------------------------------------------
		// | 通用检查：分割为：词汇text, 编码code, 权重weight
		// +---------------------------------------------------------------
		parts := strings.Split(line, "\t")
		var text, code, weight string
		if flag == 1 && len(parts) == 1 { // 一列，【汉字】：外部词库
			text = parts[0]
		} else if flag == 2 && len(parts) == 2 { // 两列，【汉字+注音】：外部词库
			text, code = parts[0], parts[1]
		} else if flag == 3 && len(parts) == 3 { // 三列，【汉字+注音+权重】：字表 base av sogou
			text, code, weight = parts[0], parts[1], parts[2]
		} else if flag == 4 && len(parts) == 2 { // 两列，【汉字+权重】：ext tencent
			text, weight = parts[0], parts[1]
		} else {
			log.Fatal("分割错误：", line)
		}

		// 检查：weight 应该是纯数字
		if weight != "" {
			_, err := strconv.Atoi(weight)
			if err != nil {
				fmt.Println("weight 非数字：", line)
			}
		}

		// 过滤特殊词条
		if specialWords.Contains(text) {
			continue
		}

		// 检查：text 和 weight 不应该含有空格
		if strings.Contains(text, " ") || strings.Contains(weight, " ") {
			fmt.Println("text 和 weight 不应该含有空格：", line)
		}

		// 检查：code 前后不应该含有空格
		if strings.HasPrefix(code, " ") || strings.HasSuffix(code, " ") {
			fmt.Println("code 前后不应该含有空格：", line)
		}

		// 检查：code 是否含有非字母，或没有小写
		for _, r := range code {
			if string(r) != " " && !unicode.IsLower(r) {
				fmt.Println("编码含有非字母或大写字母：", line)
				break
			}
		}

		// 检查：text 是否含有非汉字内容
		for _, c := range text {
			if string(c) != "·" && !unicode.Is(unicode.Han, c) {
				fmt.Println("含有非汉字内容：", line, c)
				break
			}
		}

		// 除了字表，其他词库不应该含有单个的汉字
		if dictPath != HanziPath && utf8.RuneCountInString(text) == 1 {
			fmt.Println("意外的单个汉字：", line)
		}

		// 除了 base ，其他词库不应该含有两个字的词汇
		if dictPath != BasePath && utf8.RuneCountInString(text) == 2 {
			fmt.Println("意外的两字词：", line)
		}

		// 汉字个数应该与拼音个数相等
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
				fmt.Println("汉字个数和拼音个数不相等：", text, code)
			}
		}

		// +---------------------------------------------------------------
		// | 比较耗时的检查
		// +---------------------------------------------------------------
		// 检查拼写错误，如「赞zan」写成了zna；或者存在字表中没有注音的字
		go func() {
			if dictPath != HanziPath && (flag == 2 || flag == 3) && !filterPinyins.Contains(text) {
				// 把汉字和拼音弄成一一对应关系，「拼音:pin yin」→「拼:pin」「音:yin」
				textWithoutDian := strings.ReplaceAll(text, "·", "") // 去掉间隔号
				pinyins := strings.Split(code, " ")
				i := 0
				for _, zi := range textWithoutDian {
					if !contains(hanPinyinMap[string(zi)], pinyins[i]) {
						fmt.Printf("注音错误 or 字表未包含的汉字及注音: %s - %s.+%s\n", line, string(zi), pinyins[i])
					}
					i++
				}
			}
		}()

		// 多音字注音问题检查
		go func() {
			if dictPath == ExtPath || dictPath == TencentPath {
				for _, word := range polyphoneWords.ToSlice() {
					if strings.Contains(text, word) {
						fmt.Printf("多音字注音问题：%q\n", line)
					}
				}
			}
		}()

		// 异形词检查
		go func() {
			if dictPath != HanziPath && !filterWords.Contains(text) {
				for _, wrongWord := range wrongWords.ToSlice() {
					if strings.Contains(text, wrongWord) {
						fmt.Printf("异形词汇: %s - %s\n", wrongWord, text)
					}
				}
			}
		}()
	}
}
