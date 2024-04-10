package rime

import (
	"bufio"
	"fmt"
	mapset "github.com/deckarep/golang-set/v2"
	"golang.org/x/sys/windows/registry"
	"log"
	"os"
	"os/user"
	"path"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

// 一个词的组成部分
type lemma struct {
	text   string // 汉字
	code   string // 编码
	weight int    // 权重
}

var (
	mark    = "# +_+"      // 词库中的标记符号，表示从这行开始进行检查或排序
	RimeDir = getRimeDir() // Rime 配置目录

	EmojiMapPath = filepath.Join(RimeDir, "others/emoji-map.txt")
	EmojiPath    = filepath.Join(RimeDir, "opencc/emoji.txt")

	HanziPath   = filepath.Join(RimeDir, "cn_dicts/8105.dict.yaml")
	BasePath    = filepath.Join(RimeDir, "cn_dicts/base.dict.yaml")
	ExtPath     = filepath.Join(RimeDir, "cn_dicts/ext.dict.yaml")
	TencentPath = filepath.Join(RimeDir, "cn_dicts/tencent.dict.yaml")

	HanziSet   = readToSet(HanziPath)
	BaseSet    = readToSet(BasePath)
	ExtSet     = readToSet(ExtPath)
	TencentSet = readToSet(TencentPath)

	需要注音TXT   = filepath.Join(RimeDir, "others/script/rime/需要注音.txt")
	错别字TXT    = filepath.Join(RimeDir, "others/script/rime/错别字.txt")
	汉字拼音映射TXT = filepath.Join(RimeDir, "others/script/rime/汉字拼音映射.txt")
)

// 获取 macOS/Windows Rime 配置目录
func getRimeDir() string {
	var dir string
	switch runtime.GOOS {
	case "darwin": // macOS
		u, err := user.Current()
		if err != nil {
			log.Fatalln(err)
		}
		dir = filepath.Join(u.HomeDir, "Library/Rime")
	case "windows": // Windows
		dir = getWeaselDir()
	default:
		log.Fatalf("Unsupported OS: %s so far", runtime.GOOS)
	}

	return dir
}

func getWeaselDir() string {
	keyPath := `Software\Rime\Weasel`
	valueName := "RimeUserDir"

	// Get from Windows registry
	k, err := registry.OpenKey(registry.CURRENT_USER, keyPath, registry.QUERY_VALUE)
	if err != nil {
		log.Printf("Failed to open registry key: %v\n", err)
		// Fallback to default dir
		return getDefaultWeaselDir()
	}
	defer k.Close()

	rimeUserDir, _, err := k.GetStringValue(valueName)
	if err != nil {
		log.Printf("Failed to read registry value: %v\n", err)
		// Fallback to default dir
		return getDefaultWeaselDir()
	}

	return rimeUserDir
}

func getDefaultWeaselDir() string {
	appData := os.Getenv("APPDATA") // AppData\Roaming
	if appData == "" {
		log.Fatalln("APPDATA environment variable is not set.")
	}
	return filepath.Join(appData, "Rime")
}

// 将所有词库读入 set，供检查或排序使用
func readToSet(dictPath string) mapset.Set[string] {
	set := mapset.NewSet[string]()

	file, err := os.Open(dictPath)
	if err != nil {
		log.Fatalln(err)
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	isMark := false
	for sc.Scan() {
		line := sc.Text()
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		parts := strings.Split(line, "\t")
		set.Add(parts[0])
	}

	return set
}

// 打印耗时时间
func printlnTimeCost(content string, start time.Time) {
	// fmt.Printf("%s：\t%.2fs\n", content, time.Since(start).Seconds())
	printfTimeCost(content, start)
	fmt.Println()
}

// 打印耗时时间
func printfTimeCost(content string, start time.Time) {
	fmt.Printf("%s：\t%.2fs", content, time.Since(start).Seconds())
}

// slice 是否包含 item
func contains(arr []string, item string) bool {
	for _, x := range arr {
		if item == x {
			return true
		}
	}
	return false
}

// AddWeight  为 ext、tencent 没权重的词条加上权重，有权重的改为 weight
func AddWeight(dictPath string, weight int) {
	// 控制台输出
	printlnTimeCost("加权重\t"+path.Base(dictPath), time.Now())

	// 读取到 lines 数组
	file, err := os.ReadFile(dictPath)
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(file), "\n")

	isMark := false
	for i, line := range lines {
		if !isMark {
			if strings.HasPrefix(line, mark) {
				isMark = true
			}
			continue
		}
		// 过滤空行
		if line == "" {
			continue
		}
		// 修改权重为传入的 weight，没有就加上
		parts := strings.Split(line, "\t")
		_, err := strconv.Atoi(parts[len(parts)-1])
		if err != nil {
			lines[i] = line + "\t" + strconv.Itoa(weight)
		} else {
			lines[i] = strings.Join(parts[:len(parts)-1], "\t") + "\t" + strconv.Itoa(weight)
		}
	}

	// 写入
	resultString := strings.Join(lines, "\n")
	err = os.WriteFile(dictPath, []byte(resultString), 0644)
	if err != nil {
		log.Fatal(err)
	}
}
