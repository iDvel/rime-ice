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

	// 临时
	// rime.Temp()

	// Emoji 检查和更新
	rime.CheckAndGenerateEmoji()
	fmt.Println("--------------------------------------------------")

	// 为 ext、tencent 没权重的词条加上权重，有权重的改为下面设置的权重
	rime.AddWeight(rime.ExtPath, rime.DefaultWeight)
	rime.AddWeight(rime.TencentPath, rime.DefaultWeight)
	fmt.Println("--------------------------------------------------")

	// 检查
	// _type: 1 只有汉字 2 汉字+注音 3 汉字+注音+权重 4 汉字+权重
	rime.Check(rime.HanziPath, 3)
	rime.Check(rime.BasePath, 3)
	rime.Check(rime.ExtPath, 4)
	rime.Check(rime.TencentPath, 4)
	fmt.Println("--------------------------------------------------")

	areYouOK()

	// 排序，顺便去重
	rime.Sort(rime.HanziPath, 3)
	rime.Sort(rime.BasePath, 3)
	rime.Sort(rime.ExtPath, 4)
	rime.Sort(rime.TencentPath, 4)
}

func areYouOK() {
	fmt.Println("Are you OK:")
	var isOK string
	_, _ = fmt.Scanf("%s", &isOK)
	if strings.ToLower(isOK) != "ok" {
		os.Exit(123)
	}
}
