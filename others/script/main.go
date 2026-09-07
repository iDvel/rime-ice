package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"script/rime"
	"strings"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "s":
			goto SORT
		case "t":
			rime.Temp()
			return
		case "tp":
			rime.Pinyin(filepath.Join(rime.RimeDir, "cn_dicts/temp.txt"))
			return
		}
	}

	// Emoji 检查和更新
	rime.CheckAndGenerateEmoji()
	fmt.Println("--------------------------------------------------")

	// 从 others/cn_en.txt 更新中英混输词库
	rime.CnEn()
	fmt.Println("--------------------------------------------------")

	// 为没注音的词汇半自动注音
	rime.Pinyin(rime.ExtPath)
	fmt.Println("--------------------------------------------------")

	// 为 ext、tencent 没权重的词条加上权重，有权重的改为下面设置的权重
	rime.AddWeight(rime.ExtPath, 100)
	rime.AddWeight(rime.TencentPath, 100)
	fmt.Println("--------------------------------------------------")

	// 检查
	// _type: 1 只有汉字 2 汉字+注音 3 汉字+注音+权重 4 汉字+权重
	rime.Check(rime.HanziPath, 3)
	rime.Check(rime.BasePath, 3)
	rime.Check(rime.ExtPath, 3)
	rime.Check(rime.TencentPath, 4)
	fmt.Println("--------------------------------------------------")

	// 检查同义多音字
	rime.CheckPolyphone(rime.BasePath)
	rime.CheckPolyphone(rime.ExtPath)
	fmt.Println("--------------------------------------------------")

	areYouOK()

SORT:
	// 排序，顺便去重
	rime.Sort(rime.HanziPath, 3)
	rime.Sort(filepath.Join(rime.RimeDir, "cn_dicts/41448.dict.yaml"), 2)
	rime.Sort(rime.BasePath, 3)
	rime.Sort(rime.ExtPath, 3)
	rime.Sort(rime.TencentPath, 4)
	rime.Sort(filepath.Join(rime.RimeDir, "en_dicts/en.dict.yaml"), 2)
}

func areYouOK() {
	if rime.AutoConfirm {
		fmt.Println("Auto confirm enabled. Skipping prompt.")
		return
	}

	fmt.Println("Are you OK:")
	var isOK string
	_, _ = fmt.Scanf("%s", &isOK)
	isOK = strings.ToLower(isOK)
	if isOK != "ok" && isOK != "y" && isOK != "yes" {
		os.Exit(123)
	}
}
