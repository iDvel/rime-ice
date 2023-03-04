package main

import (
	"fmt"
	"log"
	"os"
	"script/rime"
	"strings"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// 临时用的
	// rime.Temp()

	// Emoji 检查和更新
	rime.CheckEmoji()
	rime.UpdateEmojiTXT()
	fmt.Println("--------------------------------------------------")

	// 更新搜狗流行词
	rime.UpdateSogou()
	fmt.Println("--------------------------------------------------")

	// 为 sogou、ext、tencent 没权重的词条加上权重，有权重的改为下面设置的权重
	rime.AddWeight(rime.SogouPath, rime.DefaultWeight)
	rime.AddWeight(rime.ExtPath, rime.DefaultWeight)
	rime.AddWeight(rime.TencentPath, rime.DefaultWeight)
	fmt.Println("--------------------------------------------------")

	// 通用检查
	// flag: 1 只有汉字，2 汉字+注音，3 汉字+注音+权重，4 汉字+权重。
	go rime.Check(rime.HanziPath, 3)
	go rime.Check(rime.BasePath, 3)
	go rime.Check(rime.SogouPath, 3)
	go rime.Check(rime.ExtPath, 4)
	go rime.Check(rime.TencentPath, 4)

	wait()

	// 排序
	rime.Sort(rime.HanziPath, 3)
	rime.Sort(rime.BasePath, 3)
	rime.Sort(rime.SogouPath, 3)   // 对 base 中已经有的，去重
	rime.Sort(rime.ExtPath, 4)     // 对 base、sogou 中已经有的，去重
	rime.Sort(rime.TencentPath, 4) // 对 base、sogou、ext 中已经有的，去重
	// rime.SortEnDict(rime.EnPath)
}

func wait() {
	fmt.Println("检查完成后输入 OK 以继续。。。")
	var isOK string
	_, _ = fmt.Scanf("%s", &isOK)
	if strings.ToLower(isOK) != "ok" {
		os.Exit(123)
	}
	fmt.Println("--------------------------------------------------")
}
