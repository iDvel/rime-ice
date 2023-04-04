package rime

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/commander-cli/cmd"
	mapset "github.com/deckarep/golang-set/v2"
)

var filterMark = "# *_*"                 // "# *_*" 和 mark 之间是过滤词列表
var filterList = mapset.NewSet[string]() // 过滤词列表，在这个列表里的词汇，不再写入

// UpdateSogou 更新搜狗流行词
func UpdateSogou() {
	// 控制台输出
	defer updateVersion(SogouPath, getSha1(SogouPath))
	defer printfTimeCost("更新搜狗流行词", time.Now())

	makeSogouFilterList() // 0. 准备好过滤词列表
	downloadSogou()       // 1. 下载搜狗流行词加入到文件末尾
	checkAndWrite()       // 2. 过滤、去重、排序
	PrintNewWords()       // 3. 打印新增词汇

	// 弄完了删除临时用的文件，否则 VSCode 全局搜索词汇时会搜索到，影响体验
	err := os.Remove("./scel2txt/scel/sogou.scel")
	if err != nil {
		log.Fatal(err)
	}
	err = os.Remove("./scel2txt/out/luna_pinyin.sogou.dict.yaml")
	if err != nil {
		log.Fatal(err)
	}
	err = os.Remove("./scel2txt/out/sogou.txt")
	if err != nil {
		log.Fatal(err)
	}
}

// 准备好过滤词列表 filterList
func makeSogouFilterList() {
	file, err := os.Open(SogouPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isFilterMark := false
	for sc.Scan() {
		line := sc.Text()
		if line == mark {
			break
		}
		if !isFilterMark {
			if strings.Contains(line, filterMark) {
				isFilterMark = true
			}
			continue
		}
		// 判断一些可能出错的情况
		if !strings.HasPrefix(line, "# ") {
			log.Fatal("sogou 过滤列表 无效行：", line)
		}
		text := strings.TrimPrefix(line, "# ")
		if strings.ContainsAny(text, " \t") {
			log.Fatal("sogou 过滤列表 包含空字符：", line)
		}
		// 加入过滤词列表
		filterList.Add(text)
	}
}

// downloadSogou 下载搜狗流行词加入到文件末尾，如果是新词且不在过滤列表，打印出来
func downloadSogou() {
	// 下载
	url := "https://pinyin.sogou.com/d/dict/download_cell.php?id=4&name=%E7%BD%91%E7%BB%9C%E6%B5%81%E8%A1%8C%E6%96%B0%E8%AF%8D%E3%80%90%E5%AE%98%E6%96%B9%E6%8E%A8%E8%8D%90%E3%80%91&f=detail"

	// 创建 scel/ 和 out/ 文件夹
	scelDir := "./scel2txt/scel/"
	if _, err := os.Stat(scelDir); os.IsNotExist(err) {
		err := os.MkdirAll(scelDir, 0755)
		if err != nil {
			panic(err)
		}
	}
	outDir := "./scel2txt/out/"
	if _, err := os.Stat(outDir); os.IsNotExist(err) {
		err := os.MkdirAll(outDir, 0755)
		if err != nil {
			panic(err)
		}
	}

	// Get the data
	resp, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	// 创建一个文件用于保存
	out, err := os.Create(filepath.Join(scelDir, "sogou.scel"))
	if err != nil {
		panic(err)
	}
	defer out.Close()

	// 然后将响应流和文件流对接起来
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		panic(err)
	}

	// 用 Python 进行转换
	c := cmd.NewCommand("python3 scel2txt.py", cmd.WithWorkingDir("./scel2txt"))
	err = c.Execute()
	if err != nil {
		fmt.Println(c.Stderr())
		log.Fatal(err)
	}
	fmt.Printf(c.Stdout())

	// 加入到现有词库的末尾
	sogouFile, err := os.OpenFile(SogouPath, os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		panic(err)
	}
	defer sogouFile.Close()
	download, err := os.ReadFile(filepath.Join(outDir, "sogou.txt"))
	if err != nil {
		panic(err)
	}
	_, err = sogouFile.Write(download)
	if err != nil {
		panic(err)
	}
	err = sogouFile.Sync()
	if err != nil {
		log.Fatal(err)
	}
}

// checkAndWrite 过滤、去重、排序
func checkAndWrite() {
	// 打开文件
	file, err := os.OpenFile(SogouPath, os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 前缀内容和词库切片，以 mark 隔开
	prefixContents := make([]string, 0) // 前置内容切片
	contents := make([]lemma, 0)        // 词库切片

	isMark := false
	set := mapset.NewSet[string]() // 去重用的 set
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			prefixContents = append(prefixContents, line)
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		// 分割
		parts := strings.Split(line, "\t")
		var text, code, weight string
		switch len(parts) {
		case 2:
			text, code = parts[0], parts[1]
		case 3:
			text, code, weight = parts[0], parts[1], parts[2]
		default:
			log.Fatal("分割错误：", line)
		}
		// 过滤：两个字及以下的
		if utf8.RuneCountInString(text) <= 2 {
			continue
		}
		// 过滤：从过滤列表过滤掉
		if filterList.Contains(text) {
			continue
		}
		// 过滤：去重
		if set.Contains(text) {
			continue
		}
		set.Add(text)
		// 过滤：base 中已经有的就不要了
		if BaseSet.Contains(text) {
			continue
		}
		// nue → nve，lue → lve
		if strings.Contains(code, "nue") {
			code = strings.ReplaceAll(code, "nue", "nve")
		}
		if strings.Contains(code, "lue") {
			code = strings.ReplaceAll(code, "lue", "lve")
		}
		// 加入数组，没权重的默认给 DefaultWeight
		if weight == "" {
			contents = append(contents, lemma{text, code, DefaultWeight})
		} else {
			weightInt, err := strconv.Atoi(weight)
			if err != nil {
				log.Fatal(err, line)
			}
			contents = append(contents, lemma{text, code, weightInt})
		}
	}

	// 排序
	sort.Slice(contents, func(i, j int) bool {
		if contents[i].code != contents[j].code {
			return contents[i].code < contents[j].code
		}
		if contents[i].text != contents[j].text {
			return contents[i].text < contents[j].text
		}
		return false
	})

	// 准备写入
	err = file.Truncate(0)
	if err != nil {
		log.Fatal(err)
	}
	_, err = file.Seek(0, 0)
	if err != nil {
		log.Fatal(err)
	}

	// 写入前缀
	for _, content := range prefixContents {
		_, err := file.WriteString(content + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}

	// 写入词库
	for _, content := range contents {
		_, err := file.WriteString(content.text + "\t" + content.code + "\t" + strconv.Itoa(content.weight) + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}

	err = file.Sync()
	if err != nil {
		log.Fatal(err)
	}
}

// PrintNewWords 打印新增词汇
func PrintNewWords() {
	// 对比 sogou 的新旧 set，找出新词汇
	newSet := readToSet(SogouPath)
	newWords := newSet.Difference(SogouSet)
	if newWords.Cardinality() == 0 {
		return
	}

	fmt.Println("新增词汇：")

	// 打印无注音的
	// for _, word := range newWords.ToSlice() {
	// 	fmt.Println(word)
	// }

	// 把注音也打出来，方便直接校对
	file, err := os.Open(SogouPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		text := strings.Split(line, "\t")[0]
		if newWords.Contains(text) {
			fmt.Println(line)
		}
	}

	fmt.Println("count: ", newWords.Cardinality())

	// 更新全局的 set，方便后续的检查
	SogouSet = newSet
}
