# scel2txt

搜狗细胞词库转鼠须管（Rime）词库，使用 Python3 实现

## 使用

将从[搜狗官方词库网站](https://pinyin.sogou.com/dict/)下载的 `*.scel` 文件放入 `scel` 文件夹，然后运行

```shell
python3 scel2txt.py
```

## 生成的文件

* 后缀为 .txt 的同名词库文件
* 自动合并所有 *.txt 文件到 `luna_pinyin.sogou.dict.yaml`


## 搜狗细胞词库（scel格式文件） 格式说明

按照一定格式保存的 Unicode 编码文件，其中每两个字节表示一个字符（中文汉字或者英文字母）。  

主要包括两部分: 

1. 全局拼音表，在文件中的偏移值是 0x1540+4, 格式为 (py_idx, py_len, py_str)
    - py_idx: 两个字节的整数，代表这个拼音的索引
    - py_len: 两个字节的整数，拼音的字节长度
    - py_str: 当前的拼音，每个字符两个字节，总长 py_len

2. 汉语词组表，在文件中的偏移值是 0x2628 或 0x26c4, 格式为 (word_count, py_idx_count, py_idx_data, (word_len, word_str, ext_len, ext){word_count})，其中 (word_len, word, ext_len, ext){word_count} 一共重复 word_count 次, 表示拼音的相同的词一共有 word_count 个
    - word_count: 两个字节的整数，同音词数量
    - py_idx_count:  两个字节的整数，拼音的索引个数
    - py_idx_data: 两个字节表示一个整数，每个整数代表一个拼音的索引，拼音索引数 
    - word_len:两个字节的整数，代表中文词组字节数长度
    - word_str: 汉语词组，每个中文汉字两个字节，总长度 word_len
    - ext_len: 两个字节的整数，可能代表扩展信息的长度，好像都是 10
    - ext: 扩展信息，一共 10 个字节，前两个字节是一个整数(不知道是不是词频)，后八个字节全是 0，ext_len 和 ext 一共 12 个字节


## 目前已测试的词库

* [网络流行新词【官方推荐】](https://pinyin.sogou.com/dict/detail/index/4), 24923 个词
* [最详细的全国地名大全](https://pinyin.sogou.com/dict/detail/index/1316), 114572 个词
* [开发大神专用词库【官方推荐】](https://pinyin.sogou.com/dict/detail/index/75228), 430 个词
* [中国高等院校（大学）大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/20647), 7192 个词
* [宋词精选【官方推荐】](https://pinyin.sogou.com/dict/detail/index/3), 7297 个词
* [成语俗语【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15097), 46785 个词
* [计算机词汇大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15117), 10300 个词
* [论语大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/22406), 2907 个词
* [歇后语集锦【官方推荐】](https://pinyin.sogou.com/dict/detail/index/22418), 1926 个词
* [数学词汇大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15202), 15992 个词
* [物理词汇大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15203), 13107 个词
* [中国历史词汇大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15130), 20526 个词
* [饮食大全【官方推荐】](https://pinyin.sogou.com/dict/detail/index/15201), 6918 个词
* [上海市城市信息精选](https://pinyin.sogou.com/dict/detail/index/19430), 37757 个词
* [linux少量术语](https://pinyin.sogou.com/dict/detail/index/225), 136 个词

## 参考资料

1. [scel2mmseg](https://raw.githubusercontent.com/archerhu/scel2mmseg/master/scel2mmseg.py)
2. [scel-to-txt](https://raw.githubusercontent.com/xwzhong/small-program/master/scel-to-txt/scel2txt.py)
