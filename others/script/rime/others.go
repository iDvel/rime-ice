package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"strconv"
	"strings"
	"unicode/utf8"
)

// 一些临时用的函数

func Temp() {
	// GeneratePinyinTest("你的行动力")
	// GeneratePinyinTest("都挺长的")
	// GeneratePinyinTest("血条长")

	// findP(BasePath, "血")
	// Pinyin(ExtPath)
	// AddWeight(ExtPath, 100)
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

// 在词库中找到此行是否包含同义多音字，如果包含且长度大于等于3，从文件中删除这行，并将所有删除的行写入到 1.txt 中
func findP(dictPath string, ch string) {
	// open file
	file, err := os.OpenFile(dictPath, os.O_RDWR, 0666)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	outFile, err := os.Create("1.txt")
	if err != nil {
		log.Fatalln(err)
	}
	defer outFile.Close()

	lines := make([]string, 0)

	isMark := false
	sc := bufio.NewScanner(file)
	set := mapset.NewSet[string]() // 去重用的
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			lines = append(lines, line)
			if line == mark {
				isMark = true
			}
			continue
		}
		if line == "" || strings.HasPrefix(line, "#") {
			lines = append(lines, line)
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) != 3 {
			log.Fatalln("len(parts) != 3", line)
		}
		text := parts[0]
		if strings.Contains(text, ch) && utf8.RuneCountInString(text) >= 3 && !set.Contains(text) {
			outFile.WriteString(line + "\n")
		} else {
			set.Add(text)
			lines = append(lines, line)
		}
	}

	// 从 lines 重新写入 file
	file.Truncate(0)
	file.Seek(0, 0)
	for _, line := range lines {
		file.WriteString(line + "\n")
	}

	fmt.Println("done")
}
