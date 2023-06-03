package rime

import (
	"fmt"
)

// 一些临时用的函数

func Temp() {
	// defer os.Exit(11)
}

// 列出 ext 和 tencent 词库中有多少行包含多音字的词汇
func listPolyphone() {
	count := 0
	for _, line := range ExtSet.Union(TencentSet).ToSlice() {
		for _, char := range line {
			if len(hanPinyin[string(char)]) > 1 {
				count++
				break
			}
		}
	}
	fmt.Println("count:", count)
}
