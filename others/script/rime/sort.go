package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path"
	"sort"
	"strconv"
	"strings"
	"time"

	mapset "github.com/deckarep/golang-set/v2"
)

// Sort 词库排序，顺便去重
// flag: 1 只有汉字，2 汉字+注音，3 汉字+注音+权重，4 汉字+权重。
func Sort(dictPath string, flag int) {
	// 控制台输出
	defer updateVersion(dictPath, getSha1(dictPath))
	defer printfTimeCost("排序 "+path.Base(dictPath), time.Now())

	// 打开文件
	file, err := os.OpenFile(dictPath, os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 前缀内容和词库切片，前者原封不动写入，后者排序后写入
	prefixContents := make([]string, 0) // 前置内容切片
	contents := make([]lemma, 0)        // 词库切片
	aSet := mapset.NewSet[string]()     // 去重用的 set

	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		// mark 之前的写入 prefixContents
		if !isMark {
			prefixContents = append(prefixContents, line)
			if line == mark {
				isMark = true
			}
			continue
		}

		// 分割为 text、code、weight
		parts := strings.Split(line, "\t")
		text, code, weight := parts[0], "", ""

		// 检查分割长度
		if (flag == 1 || flag == 2 || flag == 3) && len(parts) != flag {
			fmt.Println("分割错误123:", line)
		}
		if flag == 4 && len(parts) != 2 {
			fmt.Println("分割错误4:", line)
		}

		// 将 base 中注释了但没删除的词汇权重调为 0
		if dictPath == BasePath && strings.HasPrefix(line, "# ") {
			parts[2] = "0"
		}

		// mark 之后的，写入到 contents

		// 自身重复的直接排除，不重复的写入
		switch flag {
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
		default:
			log.Fatal("分割错误：", line)
		}
	}

	// 排序：拼音升序、权重降序、最后直接按 Unicode 编码排序
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

	// 准备写入
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
			log.Fatal(err)
		}
	}

	// 字表、base 直接写入，不需要从其他词库去重
	if dictPath == HanziPath || dictPath == BasePath {
		for _, line := range contents {
			_, err := file.WriteString(line.text + "\t" + line.code + "\t" + strconv.Itoa(line.weight) + "\n")
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	// 其他词库需要从一个或多个词库中去重后再写入
	if contains([]string{SogouPath, ExtPath, TencentPath}, dictPath) {
		var intersect mapset.Set[string] // 交集，有交集的就是重复的，去掉
		switch dictPath {
		case SogouPath:
			intersect = SogouSet.Intersect(BaseSet)
		case ExtPath:
			intersect = ExtSet.Intersect(BaseSet.Union(SogouSet))
		case TencentPath:
			intersect = TencentSet.Intersect(BaseSet.Union(SogouSet).Union(ExtSet))
		}

		for _, line := range contents {
			if intersect.Contains(line.text) {
				fmt.Printf("%s 重复于其他词库：%s\n", strings.Split(path.Base(dictPath), ".")[0], line.text)
				continue
			}
			str := ""
			if flag == 3 { // sogou
				str = line.text + "\t" + line.code + "\t" + strconv.Itoa(line.weight) + "\n"
			} else if flag == 4 { // ext tencent
				str = line.text + "\t" + strconv.Itoa(line.weight) + "\n"
			}
			_, err := file.WriteString(str)
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	// 外部词库或临时文件，只排序，不去重
	if !contains([]string{HanziPath, BasePath, SogouPath, ExtPath, TencentPath}, dictPath) {
		switch flag {
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

	err = file.Sync()
	if err != nil {
		log.Fatal(err)
	}
}
