package rime

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

// 同义多音字
var polyphonicWords = []string{
	"谁",
	"血",
	"熟",
	"掴",
	"爪",
	"薄",
	"剥",
	"哟",
	"嚼",
	"忒", // te 不是，tui 和 tei 是
	"密钥",
	"公钥",
	"私钥",
	"甲壳",
	"掉色",
}

// 不检查的词汇
var polyphonicWordsFilter = []string{
	"咀嚼", "倒嚼", "嚼着", "咬文嚼字", "嚼用", "嚼服", "马嚼子", "嚼了", "干嚼", "边嚼边", "嚼舌", "嚼不了", "嚼动", "嚼牙",
	"淡薄", "姓薄", "微薄", "绵薄", "缘薄", "薄暮", "薄施", "薄言", "儇薄", "鄙薄", "薄的", "薄雾", "薄被", "浇薄", "薄膜", "德薄任重", "德浅行薄", "恶衣薄食", "片长薄技", "薄纸", "硗薄", "薄产", "浅薄", "薄技", "命薄", "薄利", "瘠薄", "凉薄", "薄待", "削薄", "稀薄", "薄地", "喷薄", "薄薪", "薄海", "薄酒", "薄礼", "刻薄", "薄面", "薄命", "磨薄", "薄情", "薄弱", "薄弱地带", "薄弱学校", "薄弱学校改造", "薄志弱行", "薄批细抹", "薄抹灰", "薄伽丘", "薄伽梵", "薄伽梵歌", "薄砂地", "赢得青楼薄幸名", "薄田", "薄物细故", "薄幸", "薄情", "薄葬", "厌薄", "厚积薄发", "履薄临深", "德薄望轻", "菲薄", "履薄", "孤军薄旅", "薄太后", "薄荷", "薄云",
	"剥离", "剥夺", "剥削", "剥落", "剥除", "吞剥", "撕剥", "剥茧", "剥蚀", "剥取", "剥脱", "剥啄", "剥开", "椎肤剥髓", "毕剥", "剥肤之痛", "环剥", "盘剥", "生吞活剥", "山地剥",
	"熟稔", "黄熟", "谙熟", "熟思", "熟睡", "厮熟", "精熟", "熟虑", "熟字", "熟道", "腐熟", "熟地", "熟手", "熟漆", "熟语", "熟妇", "熟路", "熟识", "熟谙", "熟习", "常熟",
	"爪哇", "爪儿", "鳞爪", "棘爪", "握爪", "爪子", "爪牙",
	"差忒", "忒弥斯", "忒修斯", "破忒头", "安菲特里忒", "阿塔兰忒", "阿佛洛狄忒", "阿芙忒娜", "忒伊亚", "得墨忒耳", "欧忒耳佩",
}

// CheckPolyphone 检查 base、ext 中同义多音字是否有两种读音
// 例如「谁的」应该同时存在 shei de 与 shui de 两种读音
func CheckPolyphone(dictPath string) {
	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	// 将含有同义多音字的词汇放入，key 为词汇，value 为注音
	// 如果注音数组只有一个，则应该补充其他读音
	m := make(map[string][]string)

	isMark := false
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) != 3 {
			continue
		}
		text, code := parts[0], parts[1]
		if containsPolyphonicWordsFilter(text) {
			continue
		}
		for _, word := range polyphonicWords {
			if strings.Contains(text, word) {
				m[text] = append(m[text], code)
			}
		}
	}

	// 遍历 m，输出单数读音的词汇
	for text, codes := range m {
		if len(codes)%2 != 0 {
			fmt.Println("⚠️ 同义多音字： " + text)
		}
	}
}

func containsPolyphonicWordsFilter(text string) bool {
	for _, filter := range polyphonicWordsFilter {
		if strings.Contains(text, filter) {
			return true
		}
	}
	return false
}
