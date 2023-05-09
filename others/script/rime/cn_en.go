package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"unicode"
)

// 多音字，手动选择注音
var polyphones = map[string]string{
	"Eul的神圣法杖 > 的":  "de",
	"艾AA > 艾":       "ai",
	"大V > 大":        "da",
	"QQ音乐 > 乐":      "yue",
	"QQ会员 > 会":      "hui",
	"QQ会员 > 员":      "yuan",
	"阿Q精神 > 阿":      "a",
	"G胖 > 胖":        "pang",
	"阿Q > 阿":        "a",
	"阿Q正传 > 阿":      "a",
	"阿Q正传 > 传":      "zhuan",
	"单边z变换 > 单":     "dan",
	"卡拉OK > 卡":      "ka",
	"IP地址 > 地":      "di",
	"IP卡 > 卡":       "ka",
	"SIM卡 > 卡":      "ka",
	"UIM卡 > 卡":      "ka",
	"USIM卡 > 卡":     "ka",
	"X染色体 > 色":      "se",
	"Y染色体 > 色":      "se",
	"蒙奇·D·路飞 > 奇":   "qi",
	"蒙奇·D·龙 > 奇":    "qi",
	"马歇尔·D·蒂奇 > 奇":  "qi",
	"蒙奇·D·卡普 > 奇":   "qi",
	"蒙奇·D·卡普 > 卡":   "ka",
	"波特卡斯·D·艾斯 > 卡": "ka",
	"波特卡斯·D·艾斯 > 艾": "ai",
	"A壳 > 壳":        "ke",
	"B壳 > 壳":        "ke",
	"C壳 > 壳":        "ke",
	"D壳 > 壳":        "ke",
	"芭比Q了 > 了":      "le",
	"江南Style > 南":   "nan",
	"三无Marblue > 无": "wu",
	"V字仇杀队 > 仇":     "chou",
	"Q弹 > 弹":        "tan",
	"M系列 > 系":       "xi",
	"阿Sir > 阿":      "a",
	"MAC地址 > 地":     "di",
	"OK了 > 了":       "le",
	"OK了吗 > 了":      "le",
	"圈X > 圈":        "quan",
	"A型血 > 血":       "xue",
	"A血型 > 血":       "xue",
	"B型血 > 血":       "xue",
	"B血型 > 血":       "xue",
	"AB型血 > 血":      "xue",
	"AB血型 > 血":      "xue",
	"O型血 > 血":       "xue",
	"O血型 > 血":       "xue",
	"没Bug > 没":      "mei",
	"没有Bug > 没":     "mei",
	"卡Bug > 卡":      "ka",
	"提Bug > 提":      "ti",
	"CT检查 > 查":      "cha",
	"N卡 > 卡":        "ka",
	"A卡 > 卡":        "ka",
	"A区 > 区":        "qu",
	"B区 > 区":        "qu",
	"C区 > 区":        "qu",
	"D区 > 区":        "qu",
	"E区 > 区":        "qu",
	"F区 > 区":        "qu",
	"IT行业 > 行":      "hang",
	"TF卡 > 卡":       "ka",
	"A屏 > 屏":        "ping",
	"A和B > 和":       "he",
	"X和Y > 和":       "he",
	"查IP > 查":       "cha",
	"VIP卡 > 卡":      "ka",
	"Chromium系 > 系": "xi",
	"Chrome系 > 系":   "xi",
}

var digitMap = map[string]string{
	"0": "ling",
	"1": "yi",
	"2": "er",
	"3": "san",
	"4": "si",
	"5": "wu",
	"6": "liu",
	"7": "qi",
	"8": "ba",
	"9": "jiu",
}

var doublePinyinMap = map[string]string{
	// 零声母
	"-a-":   "aa",
	"-e-":   "ee",
	"-o-":   "oo",
	"-ai-":  "ai",
	"-ei-":  "ei",
	"-ou-":  "ou",
	"-an-":  "an",
	"-en-":  "en",
	"-ang-": "ah",
	"-eng-": "eg",
	"-ao-":  "ao",
	"-er-":  "er",
	// zh ch sh
	"zh": "v",
	"ch": "i",
	"sh": "u",
	// 韵母
	"iu":   "q",
	"ia":   "w",
	"ua":   "w",
	"uan":  "r",
	"ue":   "t",
	"ve":   "t",
	"ing":  "y",
	"uai":  "y",
	"uo":   "o",
	"un":   "p",
	"iong": "s",
	"ong":  "s",
	"iang": "d",
	"uang": "d",
	"en":   "f",
	"eng":  "g",
	"ang":  "h",
	"an":   "j",
	"ao":   "k",
	"ai":   "l",
	"ei":   "z",
	"ie":   "x",
	"iao":  "c",
	"ui":   "v",
	"ou":   "b",
	"in":   "n",
	"ian":  "m",
}

var doublePinyinFlypyMap = map[string]string{
	// 零声母
	"-a-":   "aa",
	"-e-":   "ee",
	"-o-":   "oo",
	"-ai-":  "ai",
	"-ei-":  "ei",
	"-ou-":  "ou",
	"-an-":  "an",
	"-en-":  "en",
	"-ang-": "ah",
	"-eng-": "eg",
	"-ao-":  "ao",
	"-er-":  "er",
	// zh ch sh
	"zh": "v",
	"ch": "i",
	"sh": "u",
	// 韵母
	"iu":   "q",
	"ei":   "w",
	"uan":  "r",
	"ue":   "t",
	"ve":   "t",
	"un":   "y",
	"uo":   "o",
	"ie":   "p",
	"iong": "s",
	"ong":  "s",
	"ai":   "d",
	"en":   "f",
	"eng":  "g",
	"ang":  "h",
	"an":   "j",
	"ing":  "k",
	"uai":  "k",
	"iang": "l",
	"uang": "l",
	"ou":   "z",
	"ia":   "x",
	"ua":   "x",
	"ao":   "c",
	"ui":   "v",
	"in":   "b",
	"iao":  "n",
	"ian":  "m",
}

var doublePinyinMSPYMap = map[string]string{
	// 零声母
	"-a-":   "oa",
	"-e-":   "oe",
	"-o-":   "oo",
	"-ai-":  "ol",
	"-ei-":  "oz",
	"-ou-":  "ob",
	"-an-":  "oj",
	"-en-":  "of",
	"-ang-": "oh",
	"-eng-": "og",
	"-ao-":  "ok",
	"-er-":  "or",
	// zh ch sh
	"zh": "v",
	"ch": "i",
	"sh": "u",
	// 韵母
	"iu":   "q",
	"ia":   "w",
	"ua":   "w",
	"er":   "r",
	"uan":  "r",
	"ue":   "t",
	"uai":  "y",
	"uo":   "o",
	"un":   "p",
	"iong": "s",
	"ong":  "s",
	"iang": "d",
	"uang": "d",
	"en":   "f",
	"eng":  "g",
	"ang":  "h",
	"an":   "j",
	"ao":   "k",
	"ai":   "l",
	"ing":  ";",
	"ei":   "z",
	"ie":   "x",
	"iao":  "c",
	"ui":   "v",
	"ve":   "v",
	"ou":   "b",
	"in":   "n",
	"ian":  "m",
}

var doublePinyinZiGuangMap = map[string]string{
	// 零声母
	"-a-":   "oa",
	"-e-":   "oe",
	"-o-":   "oo",
	"-ai-":  "op",
	"-ei-":  "ok",
	"-ou-":  "oz",
	"-an-":  "or",
	"-en-":  "ow",
	"-ang-": "os",
	"-eng-": "ot",
	"-ao-":  "oq",
	"-er-":  "oj",
	// zh ch sh
	"zh": "u",
	"ch": "a",
	"sh": "i",
	// 韵母
	"ao":   "q",
	"en":   "w",
	"an":   "r",
	"eng":  "t",
	"in":   "y",
	"uai":  "y",
	"uo":   "o",
	"ai":   "p",
	"ang":  "s",
	"ie":   "d",
	"ian":  "f",
	"iang": "g",
	"uang": "g",
	"iong": "h",
	"ong":  "h",
	"er":   "j",
	"iu":   "j",
	"ei":   "k",
	"uan":  "l",
	"ing":  ";",
	"ou":   "z",
	"ia":   "x",
	"ua":   "x",
	"iao":  "b",
	"ue":   "n",
	"ui":   "n",
	"un":   "m",
}

// CnEn 从 others/cn_en.txt 生成全拼和各个双拼的中英混输词库
func CnEn() {
	// 读取
	file, err := os.Open(filepath.Join(RimeDir, "others/cn_en.txt"))
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 准备要写入的文件，先先入前缀内容
	pinyinFile, err := os.OpenFile(filepath.Join(RimeDir, "en_dicts/cn_en.dict.yaml"), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer pinyinFile.Close()
	writePrefix(pinyinFile)

	doublePinyinFile, err := os.OpenFile(filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin.dict.yaml"), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer doublePinyinFile.Close()
	writePrefix(doublePinyinFile)

	doublePinyinFlypyFile, err := os.OpenFile(filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_flypy.dict.yaml"), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer doublePinyinFlypyFile.Close()
	writePrefix(doublePinyinFlypyFile)

	doublePinyinMSPYFile, err := os.OpenFile(filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_mspy.dict.yaml"), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer doublePinyinMSPYFile.Close()
	writePrefix(doublePinyinMSPYFile)

	doublePinyinZiGuangFile, err := os.OpenFile(filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_ziguang.dict.yaml"), os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		log.Fatalln(err)
	}
	defer doublePinyinZiGuangFile.Close()
	writePrefix(doublePinyinZiGuangFile)

	// 遍历、注音、转换、写入
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.TrimSpace(line) != line {
			fmt.Println("❌ 前后有空格", line)
		}
		// 按顺序转换为全拼、自然码、小鹤、微软、紫光
		codes := textToPinyin(line)
		pinyinFile.WriteString(line + "\t" + codes[0] + "\n")
		doublePinyinFile.WriteString(line + "\t" + codes[1] + "\n")
		doublePinyinFlypyFile.WriteString(line + "\t" + codes[2] + "\n")
		doublePinyinMSPYFile.WriteString(line + "\t" + codes[3] + "\n")
		doublePinyinZiGuangFile.WriteString(line + "\t" + codes[4] + "\n")
	}
	if err := sc.Err(); err != nil {
		log.Fatalln(err)
	}
	if err := pinyinFile.Sync(); err != nil {
		log.Fatalln(err)
	}
	if err := doublePinyinFile.Sync(); err != nil {
		log.Fatalln(err)
	}
	if err := doublePinyinFlypyFile.Sync(); err != nil {
		log.Fatalln(err)
	}
	if err := doublePinyinMSPYFile.Sync(); err != nil {
		log.Fatalln(err)
	}
	if err := doublePinyinZiGuangFile.Sync(); err != nil {
		log.Fatalln(err)
	}
}

// 写入前缀内容
func writePrefix(file *os.File) {
	filename := filepath.Base(file.Name())
	name := strings.TrimSuffix(filename, ".dict.yaml")
	// name = strings.TrimPrefix(name, "cn_en_")
	fmt.Println(name)
	m := map[string]string{
		"cn_en":                       "全拼",
		"cn_en_double_pinyin":         "自然码双拼",
		"cn_en_double_pinyin_flypy":   "小鹤双拼",
		"cn_en_double_pinyin_mspy":    "微软双拼",
		"cn_en_double_pinyin_ziguang": "紫光双拼",
	}

	content := fmt.Sprintf(`# Rime dictionary
# encoding: utf-8
#
#
# https://github.com/iDvel/rime-ice
# ------- 中英混输词库 for %s -------
# 由 others/cn_en.txt 生成
#
---
name: %s
version: "1"
sort: by_weight
...
`, m[name], name)

	_, err := file.WriteString(content)
	if err != nil {
		log.Fatalln(err)
	}
}

// 转换编码，汉字转为拼音，英文不变。拼音分别转为全拼、自然码、小鹤、微软、紫光
func textToPinyin(text string) []string {
	pinyin := ""
	doublePinyin := ""
	doublePinyinFlypy := ""
	doublePinyinMSPY := ""
	doublePinyinZiGuang := ""

	parts := splitMixedWords(text)
	for _, part := range parts {
		// 特殊情况，数字转为拼音
		if _, err := strconv.Atoi(part); err == nil {
			part = digitMap[part]
		}
		if len(hanPinyin[part]) == 0 { // 英文数字，不做转换
			pinyin += part
			doublePinyin += part
			doublePinyinFlypy += part
			doublePinyinMSPY += part
			doublePinyinZiGuang += part
		} else if len(hanPinyin[part]) > 1 { // 多音字，按字典指定的读音
			if value, ok := polyphones[text+" > "+part]; ok {
				pinyin += value
				doublePinyin += convertToDoublePinyin(value, doublePinyinMap)
				doublePinyinFlypy += convertToDoublePinyin(value, doublePinyinFlypyMap)
				doublePinyinMSPY += convertToDoublePinyin(value, doublePinyinMSPYMap)
				doublePinyinZiGuang += convertToDoublePinyin(value, doublePinyinZiGuangMap)
			} else {
				log.Fatalln("❌ 未处理的多音字", text, part)
			}
		} else { // 其他，按唯一的读音
			pinyin += hanPinyin[part][0]
			doublePinyin += convertToDoublePinyin(hanPinyin[part][0], doublePinyinMap)
			doublePinyinFlypy += convertToDoublePinyin(hanPinyin[part][0], doublePinyinFlypyMap)
			doublePinyinMSPY += convertToDoublePinyin(hanPinyin[part][0], doublePinyinMSPYMap)
			doublePinyinZiGuang += convertToDoublePinyin(hanPinyin[part][0], doublePinyinZiGuangMap)
		}
	}

	return []string{
		pinyin,
		doublePinyin,
		doublePinyinFlypy,
		doublePinyinMSPY,
		doublePinyinZiGuang,
	}
}

// 中英文分割，去掉间隔号和横杠
// "哆啦A梦" → ["哆", "啦", "A", "梦"]
// "QQ号" → ["QQ", "号"]
// "Wi-Fi密码" → ["WiFi", "密", "码"]
// "特拉法尔加·D·瓦铁尔·罗" → ["特", "拉", "法", "尔", "加", "D", "瓦", "铁", "尔", "罗"]
func splitMixedWords(input string) []string {
	var result []string
	word := ""
	for _, r := range input {
		if string(r) == "·" || string(r) == "-" {
			continue
		} else if unicode.Is(unicode.Latin, r) {
			word += string(r)
		} else {
			if word != "" {
				result = append(result, word)
				word = ""
			}
			result = append(result, string(r))
		}
	}
	if word != "" {
		result = append(result, word)
	}
	return result
}

func convertToDoublePinyin(code string, m map[string]string) string {
	// 零声母
	if contains([]string{"a", "e", "o", "ai", "ei", "ou", "an", "en", "ang", "eng", "ao", "er"}, code) {
		return m["-"+code+"-"]
	}
	// 分割为声母和韵母
	consonantRegexp := regexp.MustCompile(`^(b|p|m|f|d|t|n|l|g|k|h|j|q|x|zh|ch|sh|r|z|c|s|y|w)`)
	initial := consonantRegexp.FindString(code)
	final := consonantRegexp.ReplaceAllString(code, "")
	// 声母转换
	if initial == "zh" || initial == "ch" || initial == "sh" {
		initial = m[initial]
	}
	// 韵母转换
	if len(final) > 1 {
		final = m[final]
	}
	// 其余单个的声母和韵母不转换

	return initial + final
}
