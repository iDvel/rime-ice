package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"strings"
	"time"
	"unicode/utf8"
)

func UpdateMoegirl() {
	// 使用和 UpdateSogou 一样的方法
	filterList = mapset.NewSet[string]() // 重置过滤列表

	// 控制台输出
	defer updateVersion(MoegirlPath, getSha1(MoegirlPath))
	defer printfTimeCost("更新萌娘百科", time.Now())

	// 0. 准备好过滤列表
	makeFilterList(MoegirlPath)
	// 1. 下载新的萌娘词库（暂时手动操作）
	newMoegirlFile := "/Users/dvel/Downloads/moegirl.dict.yaml"
	// 2. 将新的词汇加入到末尾，并且打印新词
	appendNewDict(MoegirlPath, newMoegirlFile)
}

func makeFilterList(dictPath string) {
	file, err := os.Open(MoegirlPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isFilterMark := false
	for sc.Scan() {
		line := sc.Text()
		// 只读取 +_+ 和 *_* 之间的内容作为过滤列表
		if line == mark {
			break
		}
		if !isFilterMark {
			if strings.Contains(line, fileterMark) {
				isFilterMark = true
			}
			continue
		}
		// 过滤列表有两种情况：
		// 【# 测试一】取【测试一】
		// 【测试二	ce shi er	100】取【测试二】
		if strings.HasPrefix(line, "# ") {
			text := strings.TrimLeft(line, "# ")
			filterList.Add(text)
		} else {
			text := strings.Split(line, "\t")[0]
			filterList.Add(text)
		}
	}
}

func appendNewDict(dictPath string, newPath string) {
	// 逐行读取 newPath，有新词则加入到 dictPath 末尾
	moegirlFile, err := os.OpenFile(dictPath, os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer moegirlFile.Close()
	newFile, err := os.Open(newPath)
	if err != nil {
		log.Fatal(err)
	}
	defer newFile.Close()

	// 需要过滤的： base+sogou+moegirl+过滤列表 filterList
	set := BaseSet.Union(SogouSet).Union(MoegirlSet).Union(filterList)
	// 新词列表
	newWords := make([]string, 0)

	sc := bufio.NewScanner(newFile)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		// 只读取 ... 这行以下的词汇
		if !isMark {
			if line == "..." {
				isMark = true
			}
			continue
		}
		text := strings.Split(line, "\t")[0]
		// 过滤
		if set.Contains(text) {
			continue
		}
		// 过滤两字词
		if utf8.RuneCountInString(text) <= 2 {
			continue
		}
		// 写入末尾
		_, err := moegirlFile.WriteString(line + "\n")
		if err != nil {
			log.Fatal(err)
		}
		newWords = append(newWords, line)
	}
	err = moegirlFile.Sync()
	if err != nil {
		log.Fatal(err)
	}

	// 打印新词
	fmt.Println("新增词汇：")
	for _, word := range newWords {
		fmt.Println(word)
	}
	fmt.Println("count: ", len(newWords))
}
