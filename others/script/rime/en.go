package rime

import (
	"bufio"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"sort"
	"strings"
)

// SortEnDict 排序 en.dict.yaml 词库
func SortEnDict(dictPath string) {
	file, err := os.OpenFile(dictPath, os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// 前缀内容和词库切片，前者原封不动写入，后者排序后写入
	prefixContents := make([]string, 0) // 前置内容切片
	contents := make([][]string, 0)     // 词库切片

	// 读取
	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			prefixContents = append(prefixContents, line)
			if line == mark {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		contents = append(contents, []string{parts[0], parts[1]})
	}

	// 排序
	sort.Slice(contents, func(i, j int) bool {
		if contents[i][1] != contents[j][1] {
			return strings.ToLower(contents[i][1]) < strings.ToLower(contents[j][1])
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

	// 写入词库
	for _, content := range contents {
		_, err := file.WriteString(strings.Join(content, "\t") + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}

	err = file.Sync()
	if err != nil {
		log.Fatal(err)
	}
}

// 将 en 词库加入 set，同时包含被注释的词汇，并且都转为小写
func readEnToSet(dictPath string) mapset.Set[string] {
	set := mapset.NewSet[string]()

	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatal(err)
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
		word := strings.Split(line, "\t")[0]
		word = strings.ToLower(word)
		if strings.HasPrefix(word, "# ") {
			word = strings.TrimLeft(word, "# ")
		}
		set.Add(word)
	}

	return set
}

// 把每行只有一个单词的 txt 文本转换为 Rime 格式的词库
func enTxtToRimeDict(txtPath string) {
	txtFile, err := os.Open(txtPath)
	if err != nil {
		log.Fatal(err)
	}
	defer txtFile.Close()

	outFile, err := os.OpenFile("rime/1.txt", os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer outFile.Close()

	sc := bufio.NewScanner(txtFile)
	for sc.Scan() {
		line := sc.Text()
		_, err := outFile.WriteString(line + "\t" + line + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}

	err = outFile.Sync()
	if err != nil {
		log.Fatal(err)
	}
}