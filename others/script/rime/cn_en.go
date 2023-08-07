package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
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
	"没bug > 没":      "mei",
	"没有bug > 没":     "mei",
	"卡bug > 卡":      "ka",
	"查bug > 查":      "cha",
	"提bug > 提":      "ti",
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
	"QQ游戏大厅 > 大":    "da",
	"QQ飞车 > 车":      "che",
}

type schema struct {
	name    string
	desc    string
	path    string
	mapping map[string]string
	file    *os.File
}

var doublePinyin = schema{
	name: "cn_en_double_pinyin",
	desc: "自然码双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin.dict.yaml"),
	mapping: map[string]string{
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
	},
}

var doublePinyinFlypy = schema{
	name: "cn_en_double_pinyin_flypy",
	desc: "小鹤双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_flypy.dict.yaml"),
	mapping: map[string]string{
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
	},
}

var doublePinyinMSPY = schema{
	name: "cn_en_double_pinyin_mspy",
	desc: "微软双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_mspy.dict.yaml"),
	mapping: map[string]string{
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
	},
}

var doublePinyinSogou = schema{
	name: "cn_en_double_pinyin_sogou",
	desc: "搜狗双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_sogou.dict.yaml"),
	mapping: map[string]string{
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
		"ve":   "t",
		"ou":   "b",
		"in":   "n",
		"ian":  "m",
	},
}

var doublePinyinZiGuang = schema{
	name: "cn_en_double_pinyin_ziguang",
	desc: "紫光双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_ziguang.dict.yaml"),
	mapping: map[string]string{
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
	},
}

var doublePinyinABC = schema{
	name: "cn_en_double_pinyin_abc",
	desc: "智能 ABC 双拼",
	path: filepath.Join(RimeDir, "en_dicts/cn_en_double_pinyin_abc.dict.yaml"),
	mapping: map[string]string{
		// 零声母
		"-a-":   "oa",
		"-e-":   "oe",
		"-o-":   "oo",
		"-ai-":  "ol",
		"-ei-":  "oq",
		"-ou-":  "ob",
		"-an-":  "oj",
		"-en-":  "of",
		"-ang-": "oh",
		"-eng-": "og",
		"-ao-":  "ok",
		"-er-":  "or",
		// zh ch sh
		"zh": "a",
		"ch": "e",
		"sh": "v",
		// 韵母
		"ao":   "k",
		"en":   "f",
		"an":   "j",
		"eng":  "g",
		"in":   "c",
		"uai":  "c",
		"uo":   "o",
		"ai":   "l",
		"ang":  "h",
		"ie":   "x",
		"ian":  "w",
		"iang": "t",
		"uang": "t",
		"iong": "s",
		"ong":  "s",
		"er":   "r",
		"iu":   "r",
		"ei":   "q",
		"uan":  "p",
		"ing":  "y",
		"ou":   "b",
		"ia":   "d",
		"ua":   "d",
		"iao":  "z",
		"ue":   "m",
		"ui":   "m",
		"un":   "n",
	},
}

// CnEn 从 others/cn_en.txt 生成全拼和各个双拼的中英混输词库
func CnEn() {
	// 控制台输出
	defer printlnTimeCost("更新中英混输 ", time.Now())

	cnEnTXT, err := os.Open(filepath.Join(RimeDir, "others/cn_en.txt"))
	if err != nil {
		log.Fatalln(err)
	}
	defer cnEnTXT.Close()

	schemas := []schema{
		{name: "cn_en", desc: "全拼", path: filepath.Join(RimeDir, "en_dicts/cn_en.dict.yaml")},
		doublePinyin,
		doublePinyinFlypy,
		doublePinyinMSPY,
		doublePinyinSogou,
		doublePinyinZiGuang,
		doublePinyinABC,
	}

	// 写入前缀内容
	for i := range schemas {
		schemas[i].file, err = os.OpenFile(schemas[i].path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
		if err != nil {
			log.Fatalln(err)
		}
		writePrefix(schemas[i])
	}

	// 转换注音并写入，顺便查重
	uniq := mapset.NewSet[string]()
	sc := bufio.NewScanner(cnEnTXT)
	for sc.Scan() {
		line := sc.Text()
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.TrimSpace(line) != line {
			fmt.Println("❌ 前后有空格", line)
		}
		if uniq.Contains(line) {
			fmt.Println("❌ 重复", line)
			continue
		}
		uniq.Add(line)
		for _, schema := range schemas {
			code := textToPinyin(line, schema)
			_, err := schema.file.WriteString(line + "\t" + "ⓘ" + code + "\n")
			if err != nil {
				log.Fatalln(err)
			}
		}
	}

	for i := range schemas {
		schemas[i].file.Close()
	}
}

// 写入前缀内容
func writePrefix(s schema) {
	content := fmt.Sprintf(`# Rime dictionary
# encoding: utf-8
#
#
# https://github.com/iDvel/rime-ice
# ------- 中英混输词库 for %s -------
# 由 others/cn_en.txt 自动生成
# 编码前的 ⓘ 符号是为了防止英文方案拼写派生时派生出全大写字母（在 melt_eng.schema.yaml 中实现）
# 示例：输入 txu 得到 T恤；输入 Txu 得到 T恤； 输入 TXU 则只会得到 TXU
---
name: %s
version: "1"
sort: by_weight
...
`, s.desc, s.name)

	_, err := s.file.WriteString(content)
	if err != nil {
		log.Fatalln(err)
	}
}

// 生成编码
func textToPinyin(text string, s schema) string {
	var code string

	parts := splitMixedWords(text)
	for _, part := range parts {
		if len(hanPinyin[part]) == 0 { // 英文数字，不做转换
			code += part
		} else if len(hanPinyin[part]) > 1 { // 多音字，按字典指定的读音
			if value, ok := polyphones[text+" > "+part]; ok {
				if s.desc == "全拼" {
					code += value
				} else {
					code += convertToDoublePinyin(value, s)
				}
			} else {
				log.Fatalln("❌ 多音字未指定读音", text, part)
			}
		} else { // 其他，按唯一的读音
			if s.desc == "全拼" {
				code += hanPinyin[part][0]
			} else {
				code += convertToDoublePinyin(hanPinyin[part][0], s)
			}
		}
	}

	return code
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

// 将全拼 code 转为双拼 code
func convertToDoublePinyin(code string, s schema) string {
	// 零声母
	if contains([]string{"a", "e", "o", "ai", "ei", "ou", "an", "en", "ang", "eng", "ao", "er"}, code) {
		return s.mapping["-"+code+"-"]
	}

	// 分割为声母和韵母
	consonantRegexp := regexp.MustCompile(`^(b|p|m|f|d|t|n|l|g|k|h|j|q|x|zh|ch|sh|r|z|c|s|y|w)`)
	initial := consonantRegexp.FindString(code)
	final := consonantRegexp.ReplaceAllString(code, "")
	// 声母转换
	if initial == "zh" || initial == "ch" || initial == "sh" {
		initial = s.mapping[initial]
	}
	// 韵母转换
	if len(final) > 1 {
		final = s.mapping[final]
	}
	// 其余单个的声母和韵母不转换

	return initial + final
}
