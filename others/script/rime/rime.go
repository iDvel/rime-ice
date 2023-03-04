package rime

import (
	"bufio"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"io"
	"log"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

// 一个词条的组成部分
type lemma struct {
	text   string // 汉字
	code   string // 编码
	weight int    // 权重
}

const (
	mark        = "# +_+" // 词库中的标记符号，表示从开始检查或排序
	HanziPath   = "/Users/dvel/Library/Rime/cn_dicts/8105.dict.yaml"
	BasePath    = "/Users/dvel/Library/Rime/cn_dicts/base.dict.yaml"
	SogouPath   = "/Users/dvel/Library/Rime/cn_dicts/sogou.dict.yaml"
	ExtPath     = "/Users/dvel/Library/Rime/cn_dicts/ext.dict.yaml"
	TencentPath = "/Users/dvel/Library/Rime/cn_dicts/tencent.dict.yaml"
	EmojiPath   = "/Users/dvel/Library/Rime/opencc/emoji-map.txt"
	EnPath      = "/Users/dvel/Library/Rime/en_dicts/en.dict.yaml"

	DefaultWeight = 100 // sogou、ext、tencet 词库中默认的权重数值
)

var (
	BaseSet    mapset.Set[string]
	SogouSet   mapset.Set[string]
	ExtSet     mapset.Set[string]
	TencentSet mapset.Set[string]
)

func init() {
	BaseSet = readToSet(BasePath)
	SogouSet = readToSet(SogouPath)
	ExtSet = readToSet(ExtPath)
	TencentSet = readToSet(TencentPath)
}

// readToSet 读取词库文件为 set
func readToSet(dictPath string) mapset.Set[string] {
	set := mapset.NewSet[string]()

	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatal(set)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		set.Add(parts[0])
	}

	return set
}

// printlnTimeCost 打印耗时时间
func printlnTimeCost(content string, start time.Time) {
	fmt.Printf("%s：\t%.2fs\n", content, time.Since(start).Seconds())
}

// printfTimeCost 打印耗时时间
func printfTimeCost(content string, start time.Time) {
	fmt.Printf("%s：\t%.2fs", content, time.Since(start).Seconds())
}

// contains slice 是否包含 item
func contains(arr []string, item string) bool {
	for _, x := range arr {
		if item == x {
			return true
		}
	}
	return false
}

// getSha1 获取文件 sha1
func getSha1(dictPath string) string {
	f, err := os.Open(dictPath)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	sha1Handle := sha1.New()
	if _, err := io.Copy(sha1Handle, f); err != nil {
		log.Fatal(err)
	}

	return hex.EncodeToString(sha1Handle.Sum(nil))
}

// updateVersion 排序后，如果文件有改动，则修改 version 日期
func updateVersion(dictPath string, oldSha1 string) {
	// 判断文件是否有改变
	newSha1 := getSha1(dictPath)
	if newSha1 == oldSha1 {
		fmt.Println()
		return
	}
	fmt.Println(" ...sorted")

	// 打开文件
	file, err := os.OpenFile(dictPath, os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 修改那一行
	arr := make([]string, 0)
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, "version:") {
			s := fmt.Sprintf("version: \"%s\"", time.Now().Format("2006-01-02"))
			arr = append(arr, s)
		} else {
			arr = append(arr, line)
		}
	}

	// 重新写入
	err = file.Truncate(0)
	if err != nil {
		log.Fatal(err)
	}
	_, err = file.Seek(0, 0)
	if err != nil {
		log.Fatal(err)
	}
	for _, line := range arr {
		_, err := file.WriteString(line + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}

	err = file.Sync()
	if err != nil {
		log.Fatal(err)
	}
}

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
