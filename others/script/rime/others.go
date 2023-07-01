package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

// 一些临时用的函数

func Temp() {
	// defer os.Exit(11)
	//
	// GeneratePinyinTest("你的行动力")
}

// 列出字表中多音字的状况：是否参与自动注音
func polyphone() {
	// open file
	file, err := os.Open(HanziPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 将所有读音读入 m
	type py struct {
		pinyin string
		weight int
		isAuto bool // 是否参与自动注音
	}
	m := make(map[string][]py)

	sc := bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if line == "..." {
				isMark = true
			}
			continue
		}
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) != 3 {
			log.Fatalln("len(parts) != 3", line)
		}
		hanzi, pinyin := parts[0], parts[1]
		weight, _ := strconv.Atoi(parts[2])
		m[hanzi] = append(m[hanzi], py{pinyin: pinyin, weight: weight})
	}

	// 判断是否参与注音
	for hanzi, pys := range m {
		if len(pys) == 1 {
			continue
		}
		// 找到最大的权重
		max := 0
		for _, py := range pys {
			if py.weight > max {
				max = py.weight
			}
		}
		// 计算其他权重相较于 max 的比值，是否大于 0.05
		for i, py := range pys {
			if py.weight == max {
				m[hanzi][i].isAuto = true
			} else if float64(py.weight)/float64(max) > 0.05 {
				m[hanzi][i].isAuto = true
			}
		}
		// 输出
		fmt.Println(hanzi)
		for _, py := range pys {
			fmt.Println(py.pinyin, py.weight, py.isAuto)
		}
	}
}
