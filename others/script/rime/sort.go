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
	"sort"
	"strconv"
	"strings"
	"time"
)

func Sort(dictPath string, _type int) {
	// 控制台输出
	defer updateVersion(dictPath, getSha1(dictPath))
	defer printfTimeCost("排序 "+path.Base(dictPath), time.Now())

	// 打开文件
	file, err := os.OpenFile(dictPath, os.O_RDWR, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 前缀内容切片、词库切片，前者原封不动写入，后者排序后写入
	prefixContents := make([]string, 0) // 前置内容
	contents := make([]lemma, 0)        // 词库
	aSet := mapset.NewSet[string]()     // 去重用的的 set

	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()

		if !isMark {
			// mark 之前的写入 prefixContents
			prefixContents = append(prefixContents, line)
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}

		// 分割为 text code weight
		parts := strings.Split(line, "\t")
		text, code, weight := parts[0], "", ""

		// 检查分割长度
		if (_type == 1 || _type == 2 || _type == 3) && len(parts) != _type {
			log.Println("分割错误123")
		}
		if _type == 4 && len(parts) != 2 {
			fmt.Println("分割错误4")
		}

		// 将 base 中注释了但没删除的词汇的权重调为 0
		if dictPath == BasePath && strings.HasPrefix(line, "# ") {
			parts[2] = "0"
		}

		// mark 之后的，写入到 contents
		// 词库自身有重复内容则直接排除，不重复的写入到 contents
		switch _type {
		case 1: // 一列 【汉字】
			if aSet.Contains(text) {
				fmt.Println("重复：", line)
				continue
			}
			aSet.Add(text)
			contents = append(contents, lemma{text: text})
		case 2: // 两列 【汉字+注音】
			text, code = parts[0], parts[1]
			if aSet.Contains(text + code) {
				fmt.Println("重复：", line)
				continue
			}
			aSet.Add(text + code)
			contents = append(contents, lemma{text: text, code: code})
		case 3: // 三列 【汉字+注音+权重】
			text, code, weight = parts[0], parts[1], parts[2]
			if aSet.Contains(text + code) {
				fmt.Println("重复：", line)
				continue
			}
			aSet.Add(text + code)
			weight, _ := strconv.Atoi(weight)
			contents = append(contents, lemma{text: text, code: code, weight: weight})
		case 4: // 两列 【汉字+权重】
			text, weight = parts[0], parts[1]
			if aSet.Contains(text) {
				fmt.Println("重复：", line)
				continue
			}
			aSet.Add(text)
			weight, _ := strconv.Atoi(weight)
			contents = append(contents, lemma{text: text, weight: weight})
		}
	}
	if err := sc.Err(); err != nil {
		log.Fatalln(err)
	}

	// 排序：拼音升序，权重降序，最后直接按 Unicode 编码排序
	sort.Slice(contents, func(i, j int) bool {
		if contents[i].code != contents[j].code {
			return contents[i].code < contents[j].code
		}
		if contents[i].weight != contents[j].weight {
			return contents[i].weight > contents[j].weight
		}
		if contents[i].text != contents[j].text {
			return contents[i].text < contents[j].text
		}
		return false
	})

	// 准备写入，清空文件，移动指针到开头
	err = file.Truncate(0)
	if err != nil {
		log.Fatalln(err)
	}
	_, err = file.Seek(0, 0)
	if err != nil {
		log.Fatalln(err)
	}

	// 写入前缀
	for _, line := range prefixContents {
		_, err := file.WriteString(line + "\n")
		if err != nil {
			log.Fatalln(err)
		}
	}

	// 字表、base 直接写入，不需要从其他词库去重
	if dictPath == HanziPath || dictPath == BasePath {
		for _, line := range contents {
			_, err := file.WriteString(line.text + "\t" + line.code + "\t" + strconv.Itoa(line.weight) + "\n")
			if err != nil {
				log.Fatalln(err)
			}
		}
	}

	// ext tencent 词库需要从一个或多个词库中去重后再写入
	if dictPath == ExtPath || dictPath == TencentPath {
		var intersect mapset.Set[string] // 交集，有交集的就是重复的
		switch dictPath {
		case ExtPath:
			intersect = ExtSet.Intersect(BaseSet)
		case TencentPath:
			intersect = TencentSet.Intersect(BaseSet.Union(ExtSet))
		}

		for _, line := range contents {
			if intersect.Contains(line.text) {
				fmt.Printf("%s 重复于其他词库：%s\n", strings.Split(path.Base(dictPath), ".")[0], line.text)
				continue
			}
			s := line.text + "\t" + strconv.Itoa(line.weight) + "\n"
			_, err := file.WriteString(s)
			if err != nil {
				log.Fatalln(err)
			}
		}
	}

	// 外部词库或临时文件，只排序，不去重
	if !contains([]string{HanziPath, BasePath, ExtPath, TencentPath}, dictPath) {
		switch _type {
		case 1:
			for _, line := range contents {
				_, err := file.WriteString(line.text + "\n")
				if err != nil {
					log.Fatalln(err)
				}
			}
		case 2:
			for _, line := range contents {
				_, err := file.WriteString(line.text + "\t" + line.code + "\n")
				if err != nil {
					log.Fatalln(err)
				}
			}
		case 3:
			for _, line := range contents {
				_, err := file.WriteString(line.text + "\t" + line.code + "\t" + strconv.Itoa(line.weight) + "\n")
				if err != nil {
					log.Fatalln(err)
				}
			}
		case 4:
			for _, line := range contents {
				_, err := file.WriteString(line.text + "\t" + strconv.Itoa(line.weight) + "\n")
				if err != nil {
					log.Fatalln(err)
				}
			}
		}
	}

	if err := file.Sync(); err != nil {
		log.Fatalln(err)
	}
}

// 获取文件 sha1
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

// 排序后，如果文件有改动，则修改 version 日期，并输出 "...sorted"
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
