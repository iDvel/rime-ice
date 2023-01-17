package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

// 临时用的或一次性的方法集

func Temp() {
}

func dictsDifference(dict1, dict2 string) {
	file1Set := readToSet(dict1)
	file2Set := readToSet(dict2)
	set := file1Set.Difference(file2Set)
	fmt.Println(set.ToSlice())
	fmt.Println(set.Cardinality())
}

func dictsIntersect(dict1, dict2 string) {
	file1Set := readToSet(dict1)
	file2Set := readToSet(dict2)
	set := file1Set.Intersect(file2Set)
	fmt.Println(set.ToSlice())
	fmt.Println(set.Cardinality())
}

func enDictsIntersect(dict1, dict2 string) {
	file1Set := readEnToSet(dict1)
	file2Set := readEnToSet(dict2)
	set := file1Set.Difference(file2Set)
	// fmt.Println(set.ToSlice())
	fmt.Println(set.Cardinality())
	file, err := os.OpenFile("rime/1.txt", os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	for _, word := range set.ToSlice() {
		_, err := file.WriteString(word + "\t" + word + "\n")
		if err != nil {
			log.Fatal(err)
		}
	}
	err = file.Sync()
	if err != nil {
		log.Fatal(err)
	}
}

func get字表汉字拼音映射() {
	file, err := os.Open(HanziPath)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	HanPinYinMap := make(map[string][]string)
	keys := make([]string, 0) // ordered map
	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.Contains(line, mark) {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		text, code := parts[0], parts[1]
		if !contains(keys, text) {
			keys = append(keys, text)
		}
		HanPinYinMap[text] = append(HanPinYinMap[text], code)
	}

	tempTXT, err := os.OpenFile("rime/temp.txt", os.O_CREATE|os.O_TRUNC|os.O_RDWR, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer tempTXT.Close()

	for _, key := range keys {
		s := key + " " + strings.Join(HanPinYinMap[key], " ") + "\n"
		_, err := tempTXT.WriteString(s)
		if err != nil {
			log.Fatal(err)
		}
	}
	err = tempTXT.Sync()
	if err != nil {
		log.Fatal(err)
	}
}
